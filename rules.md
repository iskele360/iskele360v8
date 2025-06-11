# İSKELE360 Backend Kuralları ve Yapısı

## Genel Mimari

İSKELE360 sistemi, Flutter mobil uygulaması ile Node.js tabanlı bir backend arasında iletişim kuran bir yapıya sahiptir. Bu dosya, backend'in yapısını ve kurallarını açıklamaktadır.

### Teknoloji Yığını

- **Backend Framework**: Node.js + Express.js
- **Veritabanı**: MongoDB (NoSQL)
- **Gerçek Zamanlı İletişim**: Socket.IO
- **Kimlik Doğrulama**: JWT (JSON Web Token)
- **API Formatı**: RESTful API

## Rol Sistemi

Sistemde üç temel rol bulunmaktadır:

1. **Puantajcı (supervisor)**: İşçi ve malzemeci oluşturabilir, puantaj kaydı yapabilir
2. **İşçi (isci)**: Kendi puantajlarını ve zimmetlerini görebilir
3. **Malzemeci (supplier)**: Malzeme tanımlayabilir ve işçilere zimmet oluşturabilir

## Veritabanı Şeması

### Users Koleksiyonu

```javascript
{
  _id: ObjectId,
  firstName: String,
  lastName: String,
  email: String,         // Puantajcı için gerekli
  code: String,          // İşçi ve malzemeci için gerekli, 10 haneli benzersiz kod
  password: String,      // Hash'lenmiş
  role: String,          // 'supervisor', 'isci', 'supplier'
  createdBy: ObjectId,   // Oluşturan puantajcının ID'si (işçi ve malzemeci için)
  createdAt: Date,
  updatedAt: Date
}
```

### Puantaj Koleksiyonu

```javascript
{
  _id: ObjectId,
  workerId: ObjectId,    // İşçi ID
  supervisorId: ObjectId, // Puantajcı ID
  date: Date,            // Puantaj tarihi
  hours: Number,         // Çalışma saati
  description: String,   // Açıklama (opsiyonel)
  createdAt: Date,
  updatedAt: Date
}
```

### Malzeme Koleksiyonu

```javascript
{
  _id: ObjectId,
  name: String,          // Malzeme adı
  description: String,   // Açıklama (opsiyonel)
  supplierId: ObjectId,  // Malzemeci ID
  createdAt: Date,
  updatedAt: Date
}
```

### Zimmet Koleksiyonu

```javascript
{
  _id: ObjectId,
  malzemeId: ObjectId,   // Malzeme ID
  workerId: ObjectId,    // İşçi ID
  supplierId: ObjectId,  // Malzemeci ID
  quantity: Number,      // Adet
  assignedDate: Date,    // Zimmet tarihi
  returnDate: Date,      // İade tarihi (opsiyonel)
  status: String,        // 'assigned', 'returned'
  note: String,          // Not (opsiyonel)
  createdAt: Date,
  updatedAt: Date
}
```

## API Endpointleri

### Kimlik Doğrulama

- `POST /api/auth/login`: Email ile giriş (puantajcı)
- `POST /api/auth/login-with-code`: Kod ile giriş (işçi/malzemeci)

### Kullanıcı Yönetimi

- `GET /api/users/profile`: Oturum açmış kullanıcının bilgilerini getir
- `GET /api/users/workers`: Tüm işçileri getir (puantajcı için)
- `GET /api/users/suppliers`: Tüm malzemecileri getir (puantajcı için)
- `POST /api/users/create-worker`: Yeni işçi oluştur (puantajcı için)
- `POST /api/users/create-supplier`: Yeni malzemeci oluştur (puantajcı için)
- `GET /api/users/by-code/:code`: Koda göre kullanıcı getir

### Puantaj Yönetimi

- `GET /api/puantaj/list`: Tüm puantajları getir (puantajcı için)
- `POST /api/puantaj/create`: Yeni puantaj oluştur (puantajcı için)
- `GET /api/puantaj/worker/:id`: İşçiye göre puantajları getir
- `GET /api/puantaj/supervisor/:id`: Puantajcıya göre puantajları getir

### Malzeme Yönetimi

- `GET /api/malzeme/list`: Tüm malzemeleri getir
- `POST /api/malzeme/create`: Yeni malzeme oluştur (malzemeci için)

### Zimmet Yönetimi

- `GET /api/zimmet/list`: Tüm zimmetleri getir
- `POST /api/zimmet/create`: Yeni zimmet oluştur (malzemeci için)
- `GET /api/zimmet/worker/:id`: İşçiye göre zimmetleri getir
- `GET /api/zimmet/supplier/:id`: Malzemeciye göre zimmetleri getir
- `PUT /api/zimmet/return/:id`: Zimmet iade et (malzemeci için)

## WebSocket Eventleri

- `new_puantaj`: Yeni puantaj oluşturulduğunda
- `update_puantaj`: Puantaj güncellendiğinde
- `new_zimmet`: Yeni zimmet oluşturulduğunda
- `update_zimmet`: Zimmet güncellendiğinde

## Kod Üretme Mekanizması

İşçi ve malzemeci için 10 haneli benzersiz kodlar aşağıdaki kurallara göre oluşturulur:

1. İlk 2 hane rol belirtir (01: işçi, 02: malzemeci)
2. Sonraki 4 hane timestamp'den türetilir
3. Son 4 hane rastgele üretilir
4. Tüm kodlar benzersiz olmalıdır

## Güvenlik Kuralları

1. Tüm şifreler bcrypt ile hash'lenir
2. Her API isteği JWT token kontrolünden geçer
3. Her endpoint için rol bazlı yetkilendirme kontrolleri yapılır
4. Hassas veriler şifrelenir
5. API rate limiting uygulanır

## Hata Yönetimi

Tüm API yanıtları aşağıdaki formata uygun olmalıdır:

```javascript
// Başarılı yanıt
{
  "success": true,
  "data": { ... }
}

// Hata yanıtı
{
  "success": false,
  "message": "Hata mesajı",
  "error": { ... } // (opsiyonel) hata detayları
}
``` 