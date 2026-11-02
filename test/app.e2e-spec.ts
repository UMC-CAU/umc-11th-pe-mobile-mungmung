import 'reflect-metadata';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { INestApplication } from '@nestjs/common';
import { QueryFailedError } from 'typeorm';
import request from 'supertest';
import * as bcrypt from 'bcrypt';
// Use Nest's compiled output so TypeScript decorator metadata matches production.
import { MemberController } from '../dist/controller/member.controller.js';
import { RatingController } from '../dist/controller/rating.controller.js';
import { MemberService } from '../dist/service/member.service.js';
import { RatingService } from '../dist/service/rating.service.js';
import { Member } from '../dist/entity/member.entity.js';
import { Rating } from '../dist/entity/rating.entity.js';
import { configureApp } from '../dist/configure-app.js';

describe('Checklist HTTP integration (in-memory repositories)', () => {
  let app: INestApplication;
  let members: any[];
  let ratings: any[];
  let failSave: boolean;
  const signup = {
    email: 'one@example.com',
    nickname: 'tester',
    password: 'Strong123!',
  };
  const duplicate = () =>
    new QueryFailedError(
      'INSERT',
      [],
      Object.assign(new Error('duplicate'), { code: 'ER_DUP_ENTRY' }),
    );

  beforeEach(async () => {
    members = [];
    ratings = [];
    failSave = false;
    const memberRepo = {
      create: (value: any) => ({ ...value }),
      findOneBy: async (where: any) =>
        members.find((m) =>
          Object.entries(where).every(([key, value]) => m[key] === value),
        ) ?? null,
      exists: async ({ where }: any) =>
        members.some((m) =>
          Object.entries(where).every(([key, value]) => m[key] === value),
        ),
      save: async (value: any) => {
        if (failSave) throw duplicate();
        const saved = { ...value, memberId: members.length + 1 };
        members.push(saved);
        return saved;
      },
    };
    const ratingRepo = {
      create: (value: any) => ({ ...value }),
      findOne: async ({ where }: any) =>
        ratings.find((r) =>
          where.ratingId !== undefined
            ? r.ratingId === where.ratingId
            : r.member.memberId === where.member.memberId &&
              r.movieId === where.movieId,
        ) ?? null,
      find: async ({ where }: any) =>
        ratings
          .filter((r) => r.member.memberId === where.member.memberId)
          .reverse(),
      save: async (value: any) => {
        if (failSave) throw duplicate();
        if (!value.ratingId) {
          value.ratingId = ratings.length + 1;
          value.createdAt = new Date();
          ratings.push(value);
        }
        value.updatedAt = new Date();
        return value;
      },
      remove: async (value: any) => {
        ratings.splice(ratings.indexOf(value), 1);
      },
    };
    const module = await Test.createTestingModule({
      controllers: [MemberController, RatingController],
      providers: [
        MemberService,
        RatingService,
        { provide: getRepositoryToken(Member), useValue: memberRepo },
        { provide: getRepositoryToken(Rating), useValue: ratingRepo },
      ],
    }).compile();
    app = module.createNestApplication();
    configureApp(app);
    await app.init();
  });
  afterEach(async () => {
    await app.close();
  });
  const envelope = (body: any, status: number) => {
    expect(Object.keys(body).sort()).toEqual([
      'code',
      'isSuccess',
      'message',
      'result',
    ]);
    expect(body.code).toBe('COMMON' + status);
    expect(body.isSuccess).toBe(status < 400);
    expect(typeof body.message).toBe('string');
    if (status >= 400) expect(body.result).toBeNull();
  };
  async function seed() {
    await request(app.getHttpServer())
      .post('/members')
      .send(signup)
      .expect(201);
  }

  it('hashes the password and returns a password-free member DTO', async () => {
    const { body } = await request(app.getHttpServer())
      .post('/members')
      .send(signup)
      .expect(201);
    envelope(body, 201);
    expect(body.result).toEqual({
      memberId: 1,
      email: signup.email,
      nickname: signup.nickname,
    });
    expect(members[0].password).not.toBe(signup.password);
    expect(await bcrypt.compare(signup.password, members[0].password)).toBe(
      true,
    );
  });
  it.each([
    { email: 'bad' },
    { nickname: 'a' },
    { nickname: 'x'.repeat(13) },
    { nickname: '  ' },
    { password: 'weak' },
    { password: 'Aa1!' + 'x'.repeat(69) },
    { password: null },
    { email: null },
    { extra: 'unexpected' },
    { nickname: 123 },
  ])('rejects invalid signup %j with 400', async (change) => {
    const { body } = await request(app.getHttpServer())
      .post('/members')
      .send({ ...signup, ...change })
      .expect(400);
    envelope(body, 400);
    expect(members).toHaveLength(0);
  });
  it('rejects duplicate email and nickname with 409', async () => {
    await seed();
    for (const payload of [
      { ...signup, nickname: 'other' },
      { ...signup, email: 'two@example.com' },
    ]) {
      const { body } = await request(app.getHttpServer())
        .post('/members')
        .send(payload)
        .expect(409);
      envelope(body, 409);
    }
  });
  it('uses consistent JSON envelopes and returns an empty 204 on deletion', async () => {
    await seed();
    for (const path of [
      '/members/email/free@example.com',
      '/members/nickname/free',
      '/members/1/ratings',
    ]) {
      const { body } = await request(app.getHttpServer()).get(path).expect(200);
      envelope(body, 200);
    }
    const created = await request(app.getHttpServer())
      .post('/members/1/ratings')
      .send({ movieId: 1, score: 1, comment: 'x'.repeat(500) })
      .expect(201);
    envelope(created.body, 201);
    const repeated = await request(app.getHttpServer())
      .post('/members/1/ratings')
      .send({ movieId: 1, score: 5 })
      .expect(409);
    envelope(repeated.body, 409);
    const updated = await request(app.getHttpServer())
      .patch('/members/1/ratings/1')
      .send({ score: 5, comment: 'updated' })
      .expect(200);
    envelope(updated.body, 200);
    expect(ratings[0].score).toBe(5);
    const listed = await request(app.getHttpServer())
      .get('/members/1/ratings')
      .expect(200);
    expect(listed.body.result[0].comment).toBe('updated');
    expect(JSON.stringify(listed.body)).not.toContain('password');
    const deleted = await request(app.getHttpServer())
      .delete('/members/1/ratings/1')
      .expect(204);
    expect(deleted.text).toBe('');
    expect(ratings).toHaveLength(0);
  });
  it.each([
    { score: 0 },
    { score: 6 },
    { score: 1.5 },
    { score: '3' },
    { score: null },
    { comment: 'x'.repeat(501) },
    { comment: 3 },
    { comment: {} },
  ])('validates create and update %j', async (change) => {
    await seed();
    await request(app.getHttpServer())
      .post('/members/1/ratings')
      .send({ movieId: 1, score: 3 })
      .expect(201);
    const created = await request(app.getHttpServer())
      .post('/members/1/ratings')
      .send({ movieId: 2, score: 3, ...change })
      .expect(400);
    envelope(created.body, 400);
    const updated = await request(app.getHttpServer())
      .patch('/members/1/ratings/1')
      .send({ score: 3, ...change })
      .expect(400);
    envelope(updated.body, 400);
    expect(ratings[0].score).toBe(3);
  });
  it('checks ownership before update/delete and returns 404 for missing ratings', async () => {
    await seed();
    await request(app.getHttpServer())
      .post('/members/1/ratings')
      .send({ movieId: 1, score: 3 })
      .expect(201);
    for (const method of ['patch', 'delete'] as const) {
      const forbidden = await request(app.getHttpServer())
        [method]('/members/2/ratings/1')
        .send({ score: 5 })
        .expect(403);
      envelope(forbidden.body, 403);
      const missing = await request(app.getHttpServer())
        [method]('/members/1/ratings/999')
        .send({ score: 5 })
        .expect(404);
      envelope(missing.body, 404);
    }
    expect(ratings).toHaveLength(1);
    expect(ratings[0].score).toBe(3);
  });
  it('maps database duplicate-key races to 409 for members and ratings', async () => {
    failSave = true;
    const member = await request(app.getHttpServer())
      .post('/members')
      .send(signup)
      .expect(409);
    envelope(member.body, 409);
    failSave = false;
    await seed();
    failSave = true;
    const rating = await request(app.getHttpServer())
      .post('/members/1/ratings')
      .send({ movieId: 1, score: 3 })
      .expect(409);
    envelope(rating.body, 409);
  });
  it.each([{ movieId: 0 }, { movieId: -1 }, { movieId: 1.5 }, { movieId: '1' }, { movieId: null }, { extra: true }])('rejects invalid rating identity or unknown fields %j', async (change) => {
    await seed();
    const { body } = await request(app.getHttpServer()).post('/members/1/ratings').send({ movieId: 1, score: 3, ...change }).expect(400);
    envelope(body, 400); expect(ratings).toHaveLength(0);
  });
  it('allows the same movie for different members and multiple movies for one member', async () => {
    await seed();
    await request(app.getHttpServer()).post('/members').send({ ...signup, email: 'two@example.com', nickname: 'second' }).expect(201);
    for (const [memberId, movieId] of [[1, 1], [1, 2], [2, 1]]) {
      await request(app.getHttpServer()).post(`/members/${memberId}/ratings`).send({ movieId, score: 3 }).expect(201);
    }
    expect(ratings).toHaveLength(3);
  });
  it('wraps unknown routes and malformed IDs with the error envelope', async () => {
    for (const [path, status] of [
      ['/missing', 404],
      ['/members/abc/ratings', 400], ['/members/0/ratings', 400], ['/members/-1/ratings', 400], ['/members/9007199254740992/ratings', 400],
    ] as const) {
      const { body } = await request(app.getHttpServer())
        .get(path)
        .expect(status);
      envelope(body, status);
    }
  });
});
