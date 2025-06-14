import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:redis/redis.dart';
import 'package:iskele360v7/utils/constants.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  late RedisConnection _redisConn;
  late Command _redisCommand;
  bool _redisConnected = false;

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  Future<void> init() async {
    // Hive başlat
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    // Kutuları aç
    await Hive.openBox('users');
    await Hive.openBox('puantaj');
    await Hive.openBox('malzeme');
    await Hive.openBox('settings');

    // Redis bağlantısını başlat
    try {
      _redisConn = RedisConnection();
      _redisCommand = await _redisConn.connect(
          AppConstants.redisUrl, AppConstants.redisPort);
      _redisConnected = true;
      print('Redis bağlantısı başarılı');
    } catch (e) {
      print('Redis bağlantısı başarısız: $e');
      _redisConnected = false;
    }
  }

  // Veri kaydetme
  Future<void> put(String box, String key, dynamic value) async {
    // Önce Hive'a kaydet
    final hiveBox = Hive.box(box);
    await hiveBox.put(key, value);

    // Redis'e kaydet
    if (_redisConnected) {
      try {
        final redisKey = '${box}:$key';
        final jsonValue = json.encode(value);
        await _redisCommand.send_object(['SET', redisKey, jsonValue]);
        await _redisCommand
            .send_object(['EXPIRE', redisKey, 300]); // 5 dakika TTL
      } catch (e) {
        print('Redis put hatası: $e');
      }
    }
  }

  // Veri okuma
  Future<dynamic> get(String box, String key) async {
    // Önce Redis'ten dene
    if (_redisConnected) {
      try {
        final redisKey = '${box}:$key';
        final value = await _redisCommand.send_object(['GET', redisKey]);
        if (value != null) {
          return json.decode(value.toString());
        }
      } catch (e) {
        print('Redis get hatası: $e');
      }
    }

    // Redis'ten alınamazsa Hive'dan al
    final hiveBox = Hive.box(box);
    return hiveBox.get(key);
  }

  // Tüm verileri getir
  Future<Map<dynamic, dynamic>> getAll(String box) async {
    final hiveBox = Hive.box(box);
    return hiveBox.toMap();
  }

  // Veri silme
  Future<void> delete(String box, String key) async {
    // Hive'dan sil
    final hiveBox = Hive.box(box);
    await hiveBox.delete(key);

    // Redis'ten sil
    if (_redisConnected) {
      try {
        final redisKey = '${box}:$key';
        await _redisCommand.send_object(['DEL', redisKey]);
      } catch (e) {
        print('Redis delete hatası: $e');
      }
    }
  }

  // Kutuyu temizle
  Future<void> clear(String box) async {
    // Hive'ı temizle
    final hiveBox = Hive.box(box);
    await hiveBox.clear();

    // Redis'i temizle
    if (_redisConnected) {
      try {
        final pattern = '$box:*';
        final keys = await _redisCommand.send_object(['KEYS', pattern]);
        if (keys != null && keys.isNotEmpty) {
          await _redisCommand.send_object(['DEL', ...keys]);
        }
      } catch (e) {
        print('Redis clear hatası: $e');
      }
    }
  }

  // Veri dinleme
  Stream<BoxEvent> watch(String box) {
    final hiveBox = Hive.box(box);
    return hiveBox.watch();
  }

  // Belirli bir anahtarı dinleme
  Stream<BoxEvent> watchKey(String box, String key) {
    final hiveBox = Hive.box(box);
    return hiveBox.watch(key: key);
  }

  // Redis bağlantı durumunu kontrol et
  bool get isRedisConnected => _redisConnected;

  // Redis bağlantısını yeniden dene
  Future<void> reconnectRedis() async {
    if (!_redisConnected) {
      try {
        _redisConn = RedisConnection();
        _redisCommand = await _redisConn.connect(
            AppConstants.redisUrl, AppConstants.redisPort);
        _redisConnected = true;
        print('Redis yeniden bağlantı başarılı');
      } catch (e) {
        print('Redis yeniden bağlantı başarısız: $e');
        _redisConnected = false;
      }
    }
  }
}
