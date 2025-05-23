# hayat-bank-api



## Kerakli utilitalar

1. Java JDK 17+
2. PostgresSQL 17

***

## Kerakli fayllar joylashuvi

- #### DB Backup: ***/src/main/resources/files/hayat_db.sql***
- #### Postman collection: ***/src/main/resources/files/Condidate test API.postman_collection.json***

***

### DB ni import qilish uchun 
- a) Quyidagi scriptni yurgizamiz
```sql
create role hayat with password 'Aa12345678' login;
```
- b) Backupni restore qilamiz. (Backup fayl: ***/src/main/resources/files/hayat_db.sql***)
- c) Restore bo'lgandan keyin **HAYAT** DB ga ulanib crypto extensionni enable qilish kerak bo'ladi. Quyidagi scriptdagidek:
```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;
```
***

## Postman Collectiondan foydalanish
Collection fayl joylashuvi: ***/src/main/resources/files/Condidate test API.postman_collection.json***
#### Eslatma!!! OTP kodi har doim _123456_

***

##### 1. ***Common/Ping*** ni tekshirib ko`ramiz:
```json
{
    "code": 0,
    "message": "Ping success. DB Time: 2025-05-23 12:24:25.9523+05"
}
```
##### shunaqa response qaytishi kerak

***

##### 2. ***Login and Registration/Check user by phone number*** ni ishlatamiz. Bu orqali login yoki register qilishni aniqlaymiz

```json
{
  "code": 0,
  "message": "Success",
  "otp_session": "8e2b351b47f87c3eb869feab40a11c9d8e1c8499",
  "need_register": 0
}
```
- Responseda **need_register** da qiymat _1_ kelsa ***Login and Registration/Registration*** ga o`tamiz va registratsiya qilamiz.
- Agar **need_register** da qiymat _0_ kelsa ***Login and Registration/Login via OTP*** ga o`tamiz va registratsiya qilamiz.

***

#### 3. Registratsiyadan o`tish uchun ***Login and Registration/Registration*** API ni ishlatamiz
**Request body**
```json
{
  "phone": "987654321",
  "fio":"User FISH",
  "email":"user_mail@email.mail",
  "otp_session": "4370a89edf5b1502440a9b6dc11f290d221e7456",
  "otp_code": "123456"
}
```

**Response (Success)**
```json
{
  "code": 0,
  "message": "Success",
  "auth_token": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJVc2VyIEZJU0giLCJpYXQiOjE3NDc5ODczNDd9.a4wb4nuBKPFi8Qae0VtdOAtUjDzr1eCSj--xK8r74D8",
  "refresh_token": "cyOYukN0G42l5Q8KwYkrbvK1hwMO2WY2y2SxH7F132c",
  "type": "Bearer",
  "expire_seconds": 86400
}
```
Responseda qaytgan **auth_token** va **refresh_token** variables ga yozib qo'yish kerak. Keyinchalikka avtorizatsiya uchun headerga qo'shib yuboriladi

**Response (Error)**
```json
{
  "code": 15,
  "message": "Telefon raqam xato kiritilgan. Iltimos, tekshirib qayta kiriting. Telefon raqam operator kodi (2 ta raqam) va abonent raqami (7 ta raqam)dan iborat bo`lishi kerak (Misol: 991234567)",
  "auth_token": null,
  "refresh_token": null,
  "type": "Bearer",
  "expire_seconds": 86400
}
```
***

#### 4. Avtorizatsiyadan o`tish uchun ***Login and Registration/Login via OTP*** API ni ishlatamiz
**Request body**
```json
{
  "phone": "903211609",
  "otp_session": "598655413820390e27c03e4ef4ae438d885f8efb",
  "otp_code": "123456"
}
```

**Response (Success)**
```json
{
  "code": 0,
  "message": "Success",
  "auth_token": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJCZXhyb2B6IiwiaWF0IjoxNzQ3OTg3Nzk5fQ.26lruu4tnMqWl_PZstVZnAQ9Dn4xHAcKSGpsaex2uMc",
  "refresh_token": "_Qm9UsYEKBWsBciVeXauy_NUSuPk5XrinjECVxsBAWg",
  "type": "Bearer",
  "expire_seconds": 86400
}
```
Responseda qaytgan **auth_token** va **refresh_token** variables ga yozib qo'yish kerak. Keyinchalikka avtorizatsiya uchun headerga qo'shib yuboriladi

**Response (Error)**
```json
{
  "code": 6,
  "message": "Tasdiqlash kodini to`g`ri kiriting",
  "auth_token": null,
  "refresh_token": null,
  "type": "Bearer",
  "expire_seconds": 86400
}
```
***

#### 5. Avtorizatsiya tokenini yangilash ***Login and Registration/Refresh token*** API ni ishlatamiz
**Request body**
```json
{
  "refresh_token": "_Qm9UsYEKBWsBciVeXauy_NUSuPk5XrinjECVxsBAWg"
}
```

**Response (Success)**
```json
{
  "code": 0,
  "message": "Success",
  "auth_token": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJCZXhyb2B6IiwiaWF0IjoxNzQ3OTg3Nzk5fQ.26lruu4tnMqWl_PZstVZnAQ9Dn4xHAcKSGpsaex2uMc",
  "refresh_token": "_Qm9UsYEKBWsBciVeXauy_NUSuPk5XrinjECVxsBAWg",
  "type": "Bearer",
  "expire_seconds": 86400
}
```
Responseda qaytgan **auth_token** va **refresh_token** variables ga yozib qo'yish kerak. Keyinchalikka avtorizatsiya uchun headerga qo'shib yuboriladi

**Response (Error)**
```json
{
  "code": 11,
  "message": "Foydalanuvchi topilmadi",
  "auth_token": null,
  "refresh_token": null,
  "type": "Bearer",
  "expire_seconds": 86400
}
```
Bunday holatda **HttpCode=401 (Unauthorized)** keladi. Qaytadan **(1) Check phone** qilib yurib kelish kerak.

***

#### 6. ***Dictionaries/Transaction types*** API - tranzaktsiyalar turlarini qaytaradi

**Response (Success)**
```json
{
  "code": 0,
  "message": "Success",
  "dictionary": [
    {
      "id": 1,
      "name_uz": "Hisobni to`ldirish",
      "name_ru": "Пополнение счета",
      "is_debit": 1
    },
    
    ...
    
    {
      "id": 5,
      "name_uz": "Kartangizga o`tkazma",
      "name_ru": "Перевод на вашу карту",
      "is_debit": 0
    }
  ]
}
```

***

#### 7. O'z ma'lumotlarini olish ***User/Self info***

**_Header_** ga _Authorization_ fieldiga yuqorida olingan **auth_token** qo'shib qo'yish kerak.

**Response (Success)**
```json
{
  "code": 0,
  "message": "Success",
  "self": {
    "id": 10,
    "user_statuses_id": 1,
    "fio": "Bexro`z",
    "phone": "903211609",
    "email": "bekki@mail.ru",
    "registered_date": "2025-05-23 11:05:09.82931",
    "updated_date": null,
    "balance": 3125000.0
  }
}
```

**Response (Error)**
```json
{
  "code": 11,
  "message": "Foydalanuvchi topilmadi",
  "self": null
}
```
Bunday holatda **HttpCode=401 (Unauthorized)** keladi. **(5) Refresh token** orqali tokenlarni yangilab qayta urinish kerak. Agar shunda ham 401 qaytsa **(1) Check phone** qilib yurib kelish kerak

***

#### 8. Foydalanuvchilar ro`yxatini olish ***User/Users list***
**Request body**
```json
{
  "page": 1,
  "per_page": 5
}
```

**Response (Success)**
```json
{
  "code": 0,
  "message": "Success",
  "total": 10,
  "pages": 5,
  "current": 1,
  "users": [
    {
      "id": 3,
      "user_statuses_id": 1,
      "fio": "Test FIO2",
      "phone": "334204051",
      "email": "email@email.email",
      "registered_date": "2025-05-22 16:47:20.053498",
      "updated_date": null,
      "balance": 0.0
    },
    {
      "id": 4,
      "user_statuses_id": 1,
      "fio": "FIO after changed",
      "phone": "334204050",
      "email": "info@info.info",
      "registered_date": "2025-05-22 16:49:49.866123",
      "updated_date": "2025-05-22 21:26:34.007923",
      "balance": 0.0
    }
  ]
}
```

**Response (Error)**
```json
{
  "code": 11,
  "message": "Foydalanuvchi topilmadi",
  "total": 0,
  "pages": 0,
  "current": 1,
  "users": []
}
```
Bunday holatda **HttpCode=401 (Unauthorized)** keladi. **(5) Refresh token** orqali tokenlarni yangilab qayta urinish kerak. Agar shunda ham 401 qaytsa **(1) Check phone** qilib yurib kelish kerak

***

#### 8. Foydalanuvchilar ma'lumotlarini tahrilashi (Faqat o'zinikini) ***User/Update self info***
**Request body**
```json
{
  "fio": "Hamroqulov B",
  "email": "hamroqulov_bekki@mail.ru"
}
```

**Response (Success)**
```json
{
  "code": 0,
  "message": "Success",
  "self": {
    "id": 10,
    "user_statuses_id": 1,
    "fio": "Hamroqulov B",
    "phone": "903211609",
    "email": "hamroqulov_bekki@mail.ru",
    "registered_date": "2025-05-23 11:05:09.82931",
    "updated_date": "2025-05-23 13:25:38.463834",
    "balance": 3125000.0
  }
}
```

**Response (Error)**
```json
{
  "code": 11,
  "message": "Foydalanuvchi topilmadi",
  "self": null
}
```

Bunday holatda **HttpCode=401 (Unauthorized)** keladi. **(5) Refresh token** orqali tokenlarni yangilab qayta urinish kerak. Agar shunda ham 401 qaytsa **(1) Check phone** qilib yurib kelish kerak

**Response (Error)**
```json
{
  "code": 16,
  "message": "E-Mail xato kiritilgan. Iltimos, tekshirib qayta kiriting",
  "self": null
}
```

***

#### 9. Foydalanuvchi tranzaktsiyalarini ko`rish (Faqat o'zinikini) ***Transactions/Self transactions list***
**Request body**
```json
{
  "page": 1,
  "per_page": 10
}
```

**Response (Success)**
```json
{
  "code": 0,
  "message": "Success",
  "total": 2,
  "pages": 1,
  "current": 1,
  "transactions": [
    {
      "user_fio": "Hamroqulov B",
      "user_phone": "903211609",
      "transaction_type": "Kartangizga o`tkazma",
      "status": "Qabul qilingan",
      "saldo_start": 0.0,
      "amount": 125000.0,
      "saldo_end": 125000.0,
      "is_debit": 1,
      "transaction_time": "2025-05-23 11:05:58.528411",
      "payment_details": "Kartangizga o`tkazma"
    },
    {
      "user_fio": "Hamroqulov B",
      "user_phone": "903211609",
      "transaction_type": "Hisobni to`ldirish",
      "status": "Qabul qilingan",
      "saldo_start": 125000.0,
      "amount": 3000000.0,
      "saldo_end": 3125000.0,
      "is_debit": 1,
      "transaction_time": "2025-05-23 11:07:39.422875",
      "payment_details": "Hisobni to`ldirish"
    }
  ]
}
```

**Response (Error)**
```json
{
  "code": 11,
  "message": "Foydalanuvchi topilmadi",
  "self": null
}
```

Bunday holatda **HttpCode=401 (Unauthorized)** keladi. **(5) Refresh token** orqali tokenlarni yangilab qayta urinish kerak. Agar shunda ham 401 qaytsa **(1) Check phone** qilib yurib kelish kerak

***

### 10. Foydalanuvchi shaxsiy hisobraqami bilan amaliyot (Faqat o'zini balansi bilan). 2 qismga bo`linadi
- #### 1. Foydalanuvchini yoki balansini tekshirish (tranzaktsiya turiga qarab, ya'ni, `is_debit=0` bo'lsa hisobida shuncha mablag`mavjudligini tekshirish) va OTP olish;
- #### 2. Tranzaktsiyani o'tkazish: hisobiga mablag' tushishi yoki mablag' yechilishi;

#### 10.1. Foydalanuvchini yoki balansini tekshirish va OTP olish ***Transactions/Before perform transaction***
**Request body**
```json
{
  "amount": 3000000,
  "transaction_type": 1
}
```

**Response (Success)**
```json
{
  "code": 0,
  "message": "Success",
  "otp_session": "48c59c8e46cf3e49e81feaf31687113d1bfcf9d4"
}
```

**Response (Error)**
```json
{
  "code": 11,
  "message": "Foydalanuvchi topilmadi",
  "self": null
}
```

Bunday holatda **HttpCode=401 (Unauthorized)** keladi. **(5) Refresh token** orqali tokenlarni yangilab qayta urinish kerak. Agar shunda ham 401 qaytsa **(1) Check phone** qilib yurib kelish kerak

**Response (Error)**
```json
{
  "code": 14,
  "message": "Hisobingizda yetarli mablag` mavjud emas",
  "otp_session": null
}
```

***

#### 10.2. Tranzaktsiyani o'tkazish: hisobiga mablag' tushishi yoki mablag' yechilishi ***Transactions/Perform transaction***
**Request body**
```json
{
  "amount": 3000000,
  "transaction_type": 1,
  "otp_session": "48c59c8e46cf3e49e81feaf31687113d1bfcf9d4",
  "otp_code": "123456"
}
```

**Response (Success)**
```json
{
  "code": 0,
  "message": "Success"
}
```

**Response (Error)**
```json
{
  "code": 11,
  "message": "Foydalanuvchi topilmadi",
  "self": null
}
```

Bunday holatda **HttpCode=401 (Unauthorized)** keladi. **(5) Refresh token** orqali tokenlarni yangilab qayta urinish kerak. Agar shunda ham 401 qaytsa **(1) Check phone** qilib yurib kelish kerak

**Response (Error)**
```json
{
  "code": 14,
  "message": "Hisobingizda yetarli mablag` mavjud emas"
}
```

***

#### 11. Barcha tranzaktsiyani ro`yxatini olish ***Transactions/Transactions list***
**Request body**
```json
{
  "user_phone": "",
  "transaction_type": null,
  "date_from": "",
  "date_to": "",
  "page": 1,
  "per_page": 10
}
```

Bu yerda:

_user_phone_ - qaysi foydalanuvchi bo'yicha ko'rmoqchiligimiz;

_transaction_type_ - tranzaktsiya turi bo`yicha filter (**(6) Dictionaries/Transaction types**)

_date_from_ - qaysi sanadan boshlab;

_date_to_ - qaysi sanagacha;

_page_ - qaysi sahifa;

_per_page_ - sahifada nechtadan ko`rsatish;


**Response (Success)**
```json
{
  "code": 0,
  "message": "Success",
  "total": 6,
  "pages": 2,
  "current": 1,
  "transactions": [
    {
      "user_fio": "Test FIO",
      "user_phone": "977801467",
      "transaction_type": "Davlat xizmatlari uchun to`lov",
      "status": "Qabul qilingan",
      "saldo_start": 2000.0,
      "amount": -500.0,
      "saldo_end": 1500.0,
      "is_debit": 0,
      "transaction_time": "2025-05-22 22:46:26.723874",
      "payment_details": "Davlat xizmatlari uchun to`lov"
    },
    {
      "user_fio": "Jorj Bush",
      "user_phone": "991234567",
      "transaction_type": "Davlat xizmatlari uchun to`lov",
      "status": "Qabul qilingan",
      "saldo_start": 9500000.0,
      "amount": -50000.0,
      "saldo_end": 9450000.0,
      "is_debit": 0,
      "transaction_time": "2025-05-23 10:45:38.649018",
      "payment_details": "Davlat xizmatlari uchun to`lov"
    },
    {
      "user_fio": "Tronald Damp",
      "user_phone": "900001234",
      "transaction_type": "Davlat xizmatlari uchun to`lov",
      "status": "Qabul qilingan",
      "saldo_start": 9000000.0,
      "amount": -500000.0,
      "saldo_end": 8500000.0,
      "is_debit": 0,
      "transaction_time": "2025-05-23 10:49:43.649681",
      "payment_details": "Davlat xizmatlari uchun to`lov"
    }
  ]
}
```

**Response (Error)**
```json
{
  "code": 11,
  "message": "Foydalanuvchi topilmadi",
  "self": null
}
```

Bunday holatda **HttpCode=401 (Unauthorized)** keladi. **(5) Refresh token** orqali tokenlarni yangilab qayta urinish kerak. Agar shunda ham 401 qaytsa **(1) Check phone** qilib yurib kelish kerak

**Response (Error)**
```json
{
  "code": 18,
  "message": "\"date_from\" formati \"dd.MM.yyyy\" ko`rinishida bo`lishi kerak",
  "total": null,
  "pages": null,
  "current": null,
  "transactions": null
}
```

***