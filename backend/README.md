# İskele360 API

İskele360 uygulamasının backend API'si.

## Kurulum

### Gereksinimler

- Node.js (v14+)
- MongoDB Atlas hesabı

### Adımlar

1. Bağımlılıkları yükleyin:
   ```
   npm install
   ```

2. `config.js` dosyasını düzenleyin:
   - MongoDB Atlas connection string'i kendi bağlantı bilgilerinizle güncelleyin
   - JWT_SECRET değerini güvenli bir şekilde değiştirin

3. Sunucuyu başlatın:
   ```
   npm run dev
   ```

## Google Cloud Run Deployment

1. Google Cloud CLI kurun ve giriş yapın

2. Projeyi seçin:
   ```
   gcloud config set project [PROJECT_ID]
   ```

3. Docker image'ı oluşturun ve Cloud Registry'ye gönderin:
   ```
   gcloud builds submit --tag gcr.io/[PROJECT_ID]/iskele360-api
   ```

4. Cloud Run'a deploy edin:
   ```
   gcloud run deploy iskele360-api --image gcr.io/[PROJECT_ID]/iskele360-api --platform managed --region us-central1 --allow-unauthenticated
   ```

## API Endpoints

### Auth

- `POST /api/auth/signup`: Puantajcı kaydı
- `POST /api/auth/login`: Giriş (email veya kod ile)

### Users

- `GET /api/users/me`: Kullanıcı profili
- `POST /api/users/worker`: İşçi oluşturma (puantajcı yetkisi gerekli)
- `POST /api/users/material-manager`: Malzemeci oluşturma (puantajcı yetkisi gerekli)
- `GET /api/users/workers`: Puantajcının işçilerini listeleme
- `GET /api/users/material-managers`: Puantajcının malzemecilerini listeleme 