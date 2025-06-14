# İskele360 V8 Backend

İskele360 projesinin V8 versiyonu için backend API servisi.

## Teknolojiler

- Node.js + Express
- PostgreSQL (Sequelize ORM)
- Redis (Upstash)
- Cloudinary
- Docker
- Swagger

## Özellikler

- Kullanıcı yönetimi (kayıt, login)
- Firma ve işçi yönetimi
- Puantaj kayıtları
- Avans kayıtları
- Malzeme zimmet işlemleri
- SGK karşılaştırma raporları
- Rol tabanlı yetkilendirme
- Redis önbellekleme
- API dokümantasyonu

## Kurulum

1. Repo'yu klonlayın:
\`\`\`bash
git clone https://github.com/iskele360/iskele360v8.git
cd iskele360v8
\`\`\`

2. Bağımlılıkları yükleyin:
\`\`\`bash
npm install
\`\`\`

3. .env dosyasını oluşturun:
\`\`\`bash
cp .env.example .env
\`\`\`

4. .env dosyasını düzenleyin ve gerekli değişkenleri ayarlayın.

5. Uygulamayı başlatın:
\`\`\`bash
# Development
npm run dev

# Production
npm start
\`\`\`

## Docker ile Kurulum

1. Docker image'ı build edin:
\`\`\`bash
docker build -t iskele360-backend-v8 .
\`\`\`

2. Container'ı çalıştırın:
\`\`\`bash
docker-compose up -d
\`\`\`

## API Dokümantasyonu

Swagger UI: http://localhost:8080/api-docs

## Lisans

ISC
