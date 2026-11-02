# 영화 평점 API 명세와 Postman 캡처 순서

## 준비

```powershell
cd C:\Users\82107\movie
npm run start:dev
```

MySQL과 `.env` 설정이 필요합니다. `Nest application successfully started` 로그를 확인하세요. 기본 주소는 `http://localhost:3000`입니다. 테이블은 자동 생성되지 않습니다. 평점 중복 UNIQUE 제약이 없다면 `database/ensure-rating-unique.sql`을 적용하세요.

Postman의 Import에서 `movie-api.postman_collection.json`을 가져오세요. 01부터 순서대로 Send를 누르면 됩니다. 01은 실행할 때마다 새로운 이메일/닉네임을 만들고 회원 ID를 저장합니다. 03은 평점 ID, 08은 두 번째 회원 ID를 자동 저장합니다. 별도 Environment는 필요 없습니다. 이 컬렉션은 회원 2명을 생성하고 평점 1개를 생성·수정·삭제합니다. 생성한 회원은 DB에 남습니다.

필수 캡처는 01(회원가입 201), 02(검증 실패 400), 03(평점 등록 201)입니다. 요청 메서드·URL·JSON Body와 응답 Status·JSON 본문이 함께 보이도록 캡처하세요. 요청 화면의 비밀번호는 테스트용 값만 사용하세요.

## 공통 규칙

- JSON 요청: `Content-Type: application/json`, Body → raw → JSON.
- 경로의 ID는 양의 안전한 정수입니다. 실제 응답의 ID를 사용하세요.
- 삭제 성공은 204 No Content로 본문이 없습니다. 나머지 성공·실패 응답은 `isSuccess`, `code`, `message`, `result` 네 필드를 반환합니다.
- `code`는 `COMMON` + HTTP 상태 코드입니다. 실패의 `result`는 `null`입니다.
- 검증 실패 메시지가 여러 개이면 첫 번째 메시지를 반환합니다.
- 요청 DTO에 정의되지 않은 추가 필드는 400입니다.
- 현재 로그인 토큰은 사용하지 않습니다. 수정·삭제는 경로의 `memberId`와 저장된 작성자를 비교합니다.

## 엔드포인트

| 메서드 | 경로 | 요청 본문 | 성공 |
| --- | --- | --- | --- |
| POST | `/members` | email, nickname, password | 201, 회원 객체 |
| GET | `/members/email/:email` | 없음 | 200, `{ "available": true }` |
| GET | `/members/nickname/:nickname` | 없음 | 200, `{ "available": true }` |
| GET | `/members/:memberId/ratings` | 없음 | 200, 평점 배열 |
| POST | `/members/:memberId/ratings` | movieId, score, comment(선택) | 201, 평점 ID 숫자 |
| PATCH | `/members/:memberId/ratings/:ratingId` | score, comment(선택) | 200, null |
| DELETE | `/members/:memberId/ratings/:ratingId` | 없음 | 204, 본문 없음 |

위 표의 반환값은 공통 응답의 `result` 안에 있습니다.

### 회원가입

`POST http://localhost:3000/members`

```json
{
  "email": "capture01@example.com",
  "nickname": "영화팬01",
  "password": "Strong123!"
}
```

이메일은 유효한 형식이며 최대 254자입니다. 닉네임은 앞뒤 공백 없이 2~12자입니다. 비밀번호는 ASCII 8~72자이고 영문 대문자·소문자·숫자·특수문자(`!@#$%^&*` 중 하나)를 각각 포함합니다. 비밀번호는 bcrypt 비용 계수 10으로 해시 저장하고 응답에서 제외합니다.

응답 예시(실제 ID는 DB에 따라 달라집니다):

```json
{
  "isSuccess": true,
  "code": "COMMON201",
  "message": "회원가입에 성공했습니다.",
  "result": {
    "memberId": 1,
    "email": "capture01@example.com",
    "nickname": "영화팬01"
  }
}
```

검증 실패를 캡처하려면 위 본문의 `email`만 `invalid-email`로 바꿉니다. 400 응답:

```json
{
  "isSuccess": false,
  "code": "COMMON400",
  "message": "올바른 이메일 형식이 아닙니다.",
  "result": null
}
```

동일 이메일 또는 닉네임을 다시 사용하면 409입니다. 성공 요청을 그대로 재전송하면 이메일 중복부터 검출합니다. 닉네임 중복만 확인하려면 이메일만 새로운 값으로 바꾸세요.

### 평점 등록

`POST http://localhost:3000/members/1/ratings`

경로의 `1`은 회원가입 응답의 `result.memberId`로 바꾸세요.

```json
{
  "movieId": 101,
  "score": 5,
  "comment": "재미있게 봤어요."
}
```

movieId는 양의 정수, score는 정수 1~5입니다. 숫자는 따옴표 없이 보내세요. comment는 최대 500자이고 생략하거나 null로 지정할 수 있습니다. 같은 회원은 같은 movieId에 평점을 한 번만 등록할 수 있습니다.

201 응답 예시:

```json
{
  "isSuccess": true,
  "code": "COMMON201",
  "message": "평점 등록에 성공했습니다.",
  "result": 1
}
```

`result` 숫자가 ratingId입니다. 같은 요청을 다시 보내면 409입니다. score를 6으로 바꾸면 400입니다.

### 평점 수정

`PATCH http://localhost:3000/members/1/ratings/1`

두 ID는 각각 실제 memberId, ratingId로 바꾸세요.

```json
{
  "score": 4,
  "comment": "다시 보니 평점을 수정하고 싶어요."
}
```

score는 필수입니다. movieId나 memberId를 본문에 추가하지 마세요. comment를 생략하면 기존 후기는 null로 초기화됩니다.

200 응답:

```json
{
  "isSuccess": true,
  "code": "COMMON200",
  "message": "평점 수정에 성공했습니다.",
  "result": null
}
```

### 평점 삭제

`DELETE http://localhost:3000/members/1/ratings/1`

Body는 none입니다. 성공 시 **204 No Content**이며 응답 본문은 비어 있습니다. Postman에서 상태 코드와 빈 응답 Body가 함께 보이도록 캡처하세요. 삭제 실패의 403·404는 기존 공통 JSON 형식을 사용합니다.

## 오류 캡처 순서

컬렉션 01~15를 순서대로 실행하면 아래 시나리오를 확인합니다. 403은 평점을 삭제하기 전에 확인하세요.

| 번호 | 시나리오 | 상태 | 메시지 |
| --- | --- | --- | --- |
| 02 | 회원가입 이메일 형식 오류 | 400 | 올바른 이메일 형식이 아닙니다. |
| 04 | 이미 등록한 이메일, 다른 닉네임 | 409 | 이미 사용 중인 이메일입니다. |
| 05 | 새로운 이메일, 이미 등록한 닉네임 | 409 | 이미 사용 중인 닉네임입니다. |
| 06 | score: 6 | 400 | 별점은 5점 이하여야 합니다. |
| 07 | 같은 회원 + 같은 영화에 재등록 | 409 | 이미 이 영화에 평점을 남기셨습니다. |
| 10, 11 | 두 번째 회원 ID로 첫 번째 회원의 평점 수정·삭제 | 403 | 본인이 작성한 평점만 수정하거나 삭제할 수 있습니다. |
| 14, 15 | 13에서 삭제한 평점을 다시 수정·삭제 | 404 | 존재하지 않는 평점입니다. |

403 응답 예시:

```json
{
  "isSuccess": false,
  "code": "COMMON403",
  "message": "본인이 작성한 평점만 수정하거나 삭제할 수 있습니다.",
  "result": null
}
```

DB의 실제 제약에서 동시 중복 삽입이 검출되면 409와 `이미 등록된 회원 또는 평점입니다.` 메시지를 반환합니다. 없는 회원의 평점 등록·조회는 404, 잘못된 경로 ID는 400입니다. 조회에는 비밀번호를 포함하지 않습니다.

## 자동 검증

`npm run test:e2e`는 빌드 후 HTTP 통합 테스트를 실행합니다. 실제 컨트롤러·서비스·DTO·필터·인터셉터를 사용하되 DB 저장소는 메모리 구현으로 대체합니다. 실제 MySQL 연결과 스키마 적용 여부는 Postman 실행 환경에서 별도로 확인해야 합니다.
