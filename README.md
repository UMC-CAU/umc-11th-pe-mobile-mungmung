<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>
    <p align="center">
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/v/@nestjs/core.svg" alt="NPM Version" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/l/@nestjs/core.svg" alt="Package License" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/dm/@nestjs/common.svg" alt="NPM Downloads" /></a>
<a href="https://circleci.com/gh/nestjs/nest" target="_blank"><img src="https://img.shields.io/circleci/build/github/nestjs/nest/master" alt="CircleCI" /></a>
<a href="https://discord.gg/G7Qnnhy" target="_blank"><img src="https://img.shields.io/badge/discord-online-brightgreen.svg" alt="Discord"/></a>
<a href="https://opencollective.com/nest#backer" target="_blank"><img src="https://opencollective.com/nest/backers/badge.svg" alt="Backers on Open Collective" /></a>
<a href="https://opencollective.com/nest#sponsor" target="_blank"><img src="https://opencollective.com/nest/sponsors/badge.svg" alt="Sponsors on Open Collective" /></a>
  <a href="https://paypal.me/kamilmysliwiec" target="_blank"><img src="https://img.shields.io/badge/Donate-PayPal-ff3f59.svg" alt="Donate us"/></a>
    <a href="https://opencollective.com/nest#sponsor"  target="_blank"><img src="https://img.shields.io/badge/Support%20us-Open%20Collective-41B883.svg" alt="Support us"></a>
  <a href="https://twitter.com/nestframework" target="_blank"><img src="https://img.shields.io/twitter/follow/nestframework.svg?style=social&label=Follow" alt="Follow us on Twitter"></a>
</p>
  <!--[![Backers on Open Collective](https://opencollective.com/nest/backers/badge.svg)](https://opencollective.com/nest#backer)
  [![Sponsors on Open Collective](https://opencollective.com/nest/sponsors/badge.svg)](https://opencollective.com/nest#sponsor)-->

## Description

[Nest](https://github.com/nestjs/nest) framework TypeScript starter repository.

## Project setup

### 회원·평점 API 실행 및 검증

- `.env`의 `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`을 설정하고 MySQL(3306)을 실행합니다.
- 기존 DB의 `member`, `rating` 테이블이 필요합니다. `synchronize: false`이므로 서버가 테이블이나 제약을 자동 생성하지 않습니다.
- 회원의 이메일·닉네임에 UNIQUE 제약이 있어야 합니다. 평점의 `(member_id, movie_id)` UNIQUE 제약은 MySQL 클라이언트에서 해당 DB를 선택한 뒤 `source database/ensure-rating-unique.sql`로 확인·추가할 수 있습니다. 기존 중복 데이터가 있으면 데이터를 삭제하지 않고 실패합니다.
- `npm install` 후 `npm run start:dev`로 실행합니다. 주소는 `http://localhost:3000`입니다.
- `npm test`, `npm run test:e2e`로 검증합니다. HTTP 통합 테스트는 실제 컨트롤러·서비스·검증·응답 처리를 사용하며, DB 저장소만 메모리 구현으로 대체합니다. 실제 MySQL 연결·테이블·제약 적용 여부는 별도 확인이 필요합니다.

| 요청 | 용도 | 성공 상태 |
| --- | --- | --- |
| `POST /members` | 회원가입: `email`, `nickname`, `password` | 201 |
| `GET /members/email/:email` | 이메일 중복 확인 | 200 |
| `GET /members/nickname/:nickname` | 닉네임 중복 확인 | 200 |
| `GET /members/:memberId/ratings` | 회원 평점 조회 | 200 |
| `POST /members/:memberId/ratings` | 등록: `movieId`, `score`, 선택적 `comment` | 201 |
| `PATCH /members/:memberId/ratings/:ratingId` | 수정: `score`, 선택적 `comment` | 200 |
| `DELETE /members/:memberId/ratings/:ratingId` | 삭제 | 204 (본문 없음) |

삭제 성공은 204 No Content로 본문을 반환하지 않습니다. 나머지 응답은 `{ "isSuccess": true, "code": "COMMON200", "message": "...", "result": ... }` 형식입니다. 실패 시 `isSuccess`는 `false`, `result`는 `null`이며 `code`에 HTTP 상태 코드가 들어갑니다. 중복 확인의 `available`과 평점 목록은 `result` 안에 있습니다.

닉네임은 앞뒤 공백 없이 2~12자, 비밀번호는 영문 대·소문자/숫자/지정 특수문자(`!@#$%^&*`)를 각각 포함하는 ASCII 8~72자입니다. 비밀번호는 bcrypt로 해시하며 회원 응답 DTO에는 포함하지 않습니다. 평점은 정수 1~5, 후기는 최대 500자이고 생략하거나 `null`로 설정할 수 있습니다. 수정 시 후기를 생략하면 `null`로 초기화합니다.

수정·삭제는 경로의 `memberId`와 저장된 평점 소유자를 비교합니다. 이 비교는 요청된 체크리스트 범위이며, 로그인 인증을 대신하지는 않습니다.

```bash
$ npm install
```

## Compile and run the project

```bash
# development
$ npm run start

# watch mode
$ npm run start:dev

# production mode
$ npm run start:prod
```

## Run tests

```bash
# unit tests
$ npm run test

# e2e tests
$ npm run test:e2e

# test coverage
$ npm run test:cov
```

## Deployment

When you're ready to deploy your NestJS application to production, there are some key steps you can take to ensure it runs as efficiently as possible. Check out the [deployment documentation](https://docs.nestjs.com/deployment) for more information.

If you are looking for a cloud-based platform to deploy your NestJS application, check out [Mau](https://mau.nestjs.com), our official platform for deploying NestJS applications on AWS. Mau makes deployment straightforward and fast, requiring just a few simple steps:

```bash
$ npm install -g @nestjs/mau
$ mau deploy
```

With Mau, you can deploy your application in just a few clicks, allowing you to focus on building features rather than managing infrastructure.

## Observability

In production applications, observability is essential for understanding how your system behaves, detecting issues early, and maintaining reliable performance.

[NestJS Observe](https://observe.nestjs.com) automatically instruments your NestJS application, giving you deep visibility into your system with minimal setup:

- **Distributed tracing:** Follow requests across services and understand how they flow through your system.
- **Waterfall analysis:** Visualize request execution and identify slow operations, bottlenecks, and unexpected delays.
- **Performance analysis:** Analyze application performance in real time and quickly pinpoint areas that need optimization.
- **Metrics:** Track key application and infrastructure metrics to understand system health and performance trends.
- **Logging:** Centralize and correlate logs with traces and other telemetry to make debugging easier.
- **Error tracking:** Detect errors quickly and investigate their root causes with the surrounding context.
- **SLA monitoring:** Track service-level objectives and identify when your application is approaching or exceeding defined thresholds.
- **Alarms and alerts:** Set up alerts for critical errors, performance degradation, SLA violations, and other anomalies so your team can react quickly.

## Resources

Check out a few resources that may come in handy when working with NestJS:

- Visit the [NestJS Documentation](https://docs.nestjs.com) to learn more about the framework.
- For questions and support, please visit our [Discord channel](https://discord.gg/G7Qnnhy).
- To dive deeper and get more hands-on experience, check out our official video [courses](https://courses.nestjs.com/).
- Deploy your application to AWS with the help of [NestJS Mau](https://mau.nestjs.com) in just a few clicks.
- Auto-instrument your application with [NestJS Observer](https://observer.nestjs.com). Distributed tracing, metrics, and logging made easy. Error tracking and performance monitoring for your NestJS applications.
- Visualize your application graph and interact with the NestJS application in real-time using [NestJS Devtools](https://devtools.nestjs.com).
- Need help with your project (part-time to full-time)? Check out our official [enterprise support](https://enterprise.nestjs.com).
- To stay in the loop and get updates, follow us on [X](https://x.com/nestframework) and [LinkedIn](https://linkedin.com/company/nestjs).
- Looking for a job, or have a job to offer? Check out our official [Jobs board](https://jobs.nestjs.com).

## Support

Nest is an MIT-licensed open source project. It can grow thanks to the sponsors and support by the amazing backers. If you'd like to join them, please [read more here](https://docs.nestjs.com/support).

## Stay in touch

- Author - [Kamil Myśliwiec](https://twitter.com/kammysliwiec)
- Website - [https://nestjs.com](https://nestjs.com/)
- Twitter - [@nestframework](https://twitter.com/nestframework)

## License

Nest is [MIT licensed](https://github.com/nestjs/nest/blob/master/LICENSE).
