const Puantaj = require('../models/Puantaj');
const User = require('../models/User');
const socketService = require('../services/socketService');

// Yeni puantaj kaydı oluştur
exports.createPuantaj = async (req, res) => {
  try {
    const {
      isciId, 
      baslangicSaati, 
      bitisSaati, 
      calismaSuresi, 
      projeId, 
      projeBilgisi,
      aciklama,
      tarih
    } = req.body;

    // İşçinin varlığını kontrol et
    const isci = await User.findById(isciId);
    
    if (!isci) {
      return res.status(404).json({
        success: false,
        message: 'İşçi bulunamadı'
      });
    }
    
    // İşçinin puantajcıya ait olup olmadığını kontrol et
    if (isci.createdBy && isci.createdBy.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Sadece kendi oluşturduğunuz işçiler için puantaj kaydı oluşturabilirsiniz'
      });
    }

    // Puantaj kaydı oluştur
    const puantaj = await Puantaj.create({
      isciId,
      puantajciId: req.user._id,
      baslangicSaati,
      bitisSaati,
      calismaSuresi,
      projeId,
      projeBilgisi,
      aciklama: aciklama || '',
      tarih: tarih || new Date()
    });

    // Socket.IO ile işçiye bildirim gönder
    socketService.emitToUser(isciId, 'puantaj_created', {
      puantaj,
      message: 'Yeni puantaj kaydı oluşturuldu'
    });

    // Başarılı yanıt
    res.status(201).json({
      success: true,
      data: puantaj
    });
  } catch (error) {
    console.error('Puantaj oluşturma hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

// Puantaj kaydını güncelle
exports.updatePuantaj = async (req, res) => {
  try {
    const { id } = req.params;
    const {
      baslangicSaati, 
      bitisSaati, 
      calismaSuresi, 
      projeId, 
      projeBilgisi,
      aciklama,
      durum
    } = req.body;

    // Puantaj kaydını bul
    const puantaj = await Puantaj.findById(id);

    if (!puantaj) {
      return res.status(404).json({
        success: false,
        message: 'Puantaj kaydı bulunamadı'
      });
    }

    // Sadece puantaj kaydını oluşturan kişi güncelleyebilir
    if (puantaj.puantajciId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Sadece kendi oluşturduğunuz puantaj kayıtlarını güncelleyebilirsiniz'
      });
    }

    // Güncelleme
    const updatedPuantaj = await Puantaj.findByIdAndUpdate(
      id,
      {
        baslangicSaati: baslangicSaati || puantaj.baslangicSaati,
        bitisSaati: bitisSaati || puantaj.bitisSaati,
        calismaSuresi: calismaSuresi || puantaj.calismaSuresi,
        projeId: projeId || puantaj.projeId,
        projeBilgisi: projeBilgisi || puantaj.projeBilgisi,
        aciklama: aciklama !== undefined ? aciklama : puantaj.aciklama,
        durum: durum || puantaj.durum
      },
      { new: true, runValidators: true }
    );

    // Socket.IO ile işçiye bildirim gönder
    socketService.emitToUser(puantaj.isciId, 'puantaj_updated', {
      puantaj: updatedPuantaj,
      message: 'Puantaj kaydı güncellendi'
    });

    // Başarılı yanıt
    res.status(200).json({
      success: true,
      data: updatedPuantaj
    });
  } catch (error) {
    console.error('Puantaj güncelleme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

// Puantaj kaydını sil
exports.deletePuantaj = async (req, res) => {
  try {
    const { id } = req.params;

    // Puantaj kaydını bul
    const puantaj = await Puantaj.findById(id);

    if (!puantaj) {
      return res.status(404).json({
        success: false,
        message: 'Puantaj kaydı bulunamadı'
      });
    }

    // Sadece puantaj kaydını oluşturan kişi silebilir
    if (puantaj.puantajciId.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Sadece kendi oluşturduğunuz puantaj kayıtlarını silebilirsiniz'
      });
    }

    // Puantaj kaydını sil
    await Puantaj.findByIdAndDelete(id);

    // Socket.IO ile işçiye bildirim gönder
    socketService.emitToUser(puantaj.isciId, 'puantaj_deleted', {
      puantajId: id,
      message: 'Puantaj kaydı silindi'
    });

    // Başarılı yanıt
    res.status(200).json({
      success: true,
      message: 'Puantaj kaydı başarıyla silindi'
    });
  } catch (error) {
    console.error('Puantaj silme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

// İşçinin puantaj kayıtlarını getir
exports.getIsciPuantajlari = async (req, res) => {
  try {
    const { isciId } = req.params;
    
    // İşçinin varlığını kontrol et
    const isci = await User.findById(isciId);
    
    if (!isci) {
      return res.status(404).json({
        success: false,
        message: 'İşçi bulunamadı'
      });
    }
    
    // İşçi kendi puantajlarını görebilir veya onu oluşturan puantajcı görebilir
    if (req.user.role === 'isci' && req.user._id.toString() !== isciId) {
      return res.status(403).json({
        success: false,
        message: 'Sadece kendi puantaj kayıtlarınızı görüntüleyebilirsiniz'
      });
    }
    
    if (req.user.role === 'puantajcı' && isci.createdBy && isci.createdBy.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Sadece kendi oluşturduğunuz işçilerin puantaj kayıtlarını görüntüleyebilirsiniz'
      });
    }
    
    // Puantaj kayıtlarını getir (en yeni tarih başta)
    const puantajlar = await Puantaj.find({ isciId })
      .sort({ tarih: -1, createdAt: -1 });
    
    // Başarılı yanıt
    res.status(200).json({
      success: true,
      count: puantajlar.length,
      data: puantajlar
    });
  } catch (error) {
    console.error('Puantaj listeleme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
};

// Puantajcının oluşturduğu tüm puantaj kayıtlarını getir
exports.getPuantajciPuantajlari = async (req, res) => {
  try {
    // Puantajcı ID'si (varsayılan olarak giriş yapan kullanıcı)
    const puantajciId = req.params.puantajciId || req.user._id;
    
    // Farklı bir puantajcının kayıtlarını görüntülemeye çalışırken yetki kontrolü
    if (req.params.puantajciId && req.params.puantajciId !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Sadece kendi oluşturduğunuz puantaj kayıtlarını görüntüleyebilirsiniz'
      });
    }
    
    // Puantaj kayıtlarını getir (en yeni tarih başta)
    const puantajlar = await Puantaj.find({ puantajciId })
      .sort({ tarih: -1, createdAt: -1 })
      .populate('isciId', 'name surname code');
    
    // Başarılı yanıt
    res.status(200).json({
      success: true,
      count: puantajlar.length,
      data: puantajlar
    });
  } catch (error) {
    console.error('Puantaj listeleme hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Sunucu hatası, lütfen daha sonra tekrar deneyin'
    });
  }
}; 