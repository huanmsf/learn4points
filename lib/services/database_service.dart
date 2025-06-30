import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart';
import '../models/question.dart';
import '../models/wrong_question.dart';
import '../utils/text_parser.dart';

// 只在非Web平台导入sqflite
import 'package:sqflite/sqflite.dart' if (dart.library.html) 'database_web_stub.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Hive数据库
  Box<Question>? _questionsBox;
  Box<WrongQuestion>? _wrongQuestionsBox;
  
  // SQLite数据库（仅非Web平台）
  Database? _database;
  
  // 文本解析器
  final TextParser _textParser = TextParser();

  /// 初始化数据库
  Future<void> initialize() async {
    await _initializeHive();
    
    // 只在非Web平台初始化SQLite
    if (!kIsWeb) {
      await _initializeSQLite();
    }
  }

  /// 初始化Hive数据库
  Future<void> _initializeHive() async {
    try {
      _questionsBox = await Hive.openBox<Question>('questions');
      _wrongQuestionsBox = await Hive.openBox<WrongQuestion>('wrong_questions');
      print('✅ Hive数据库初始化成功');
    } catch (e) {
      print('❌ Hive数据库初始化失败: $e');
    }
  }

  /// 初始化SQLite数据库（仅非Web平台）
  Future<void> _initializeSQLite() async {
    if (kIsWeb) {
      print('ℹ️ Web平台跳过SQLite初始化，使用Hive作为主要存储');
      return;
    }
    
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'quiz_helper.db');
      
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _createTables,
        onUpgrade: _upgradeTables,
      );
      
      print('✅ SQLite数据库初始化成功');
    } catch (e) {
      print('❌ SQLite数据库初始化失败: $e');
    }
  }

  /// 创建数据表
  Future<void> _createTables(Database db, int version) async {
    // 题目表
    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        number INTEGER,
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        options TEXT NOT NULL,
        correct_answers TEXT NOT NULL,
        image_url TEXT,
        created_at INTEGER NOT NULL,
        last_used_at INTEGER,
        usage_count INTEGER DEFAULT 0,
        confidence REAL DEFAULT 0.0,
        answer_source TEXT NOT NULL
      )
    ''');

    // 错题表
    await db.execute('''
      CREATE TABLE wrong_questions (
        id TEXT PRIMARY KEY,
        question_id TEXT NOT NULL,
        user_answers TEXT NOT NULL,
        wrong_time INTEGER NOT NULL,
        wrong_count INTEGER DEFAULT 1,
        last_wrong_time INTEGER,
        note TEXT,
        FOREIGN KEY (question_id) REFERENCES questions (id)
      )
    ''');

    // 创建索引
    await db.execute('CREATE INDEX idx_questions_content ON questions(content)');
    await db.execute('CREATE INDEX idx_questions_type ON questions(type)');
    await db.execute('CREATE INDEX idx_wrong_questions_time ON wrong_questions(wrong_time)');
  }

  /// 数据库升级
  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
      // 处理数据库升级逻辑
      print('数据库从版本 $oldVersion 升级到 $newVersion');
    }
  }

  // === 题目相关操作 ===

  /// 插入题目
  Future<void> insertQuestion(Question question) async {
    try {
      // 保存到Hive
      await _questionsBox?.put(question.id, question);
      
      // 保存到SQLite（仅非Web平台）
      if (!kIsWeb && _database != null) {
        await _database!.insert(
          'questions',
          _questionToMap(question),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      print('✅ 题目保存成功: ${question.content.substring(0, 20)}...');
    } catch (e) {
      print('❌ 题目保存失败: $e');
    }
  }

  /// 根据内容查找题目
  Future<Question?> findQuestionByContent(String content) async {
    try {
      // 先从Hive查找
      final questions = _questionsBox?.values.toList() ?? [];
      for (final question in questions) {
        if (question.content == content) {
          return question;
        }
      }

      // 再从SQLite查找（仅非Web平台）
      if (!kIsWeb && _database != null) {
        final List<Map<String, dynamic>> maps = await _database!.query(
          'questions',
          where: 'content = ?',
          whereArgs: [content],
          limit: 1,
        );

        if (maps.isNotEmpty) {
          return _mapToQuestion(maps.first);
        }
      }

      return null;
    } catch (e) {
      print('查找题目失败: $e');
      return null;
    }
  }

  /// 根据题干内容和题型查找题目（精确匹配）
  Future<Question?> findQuestionByContentAndType(String content, QuestionType type) async {
    try {
      // 先从Hive查找
      final questions = _questionsBox?.values.toList() ?? [];
      for (final question in questions) {
        if (question.content == content && question.type == type) {
          print('🎯 找到精确匹配题目: ${question.content.substring(0, 30)}...');
          return question;
        }
      }

      // 再从SQLite查找（仅非Web平台）
      if (!kIsWeb && _database != null) {
        final List<Map<String, dynamic>> maps = await _database!.query(
          'questions',
          where: 'content = ? AND type = ?',
          whereArgs: [content, type.toString().split('.').last],
          limit: 1,
        );

        if (maps.isNotEmpty) {
          final question = _mapToQuestion(maps.first);
          print('🎯 SQLite找到精确匹配题目: ${question.content.substring(0, 30)}...');
          return question;
        }
      }

      return null;
    } catch (e) {
      print('❌ 根据内容和题型查找题目失败: $e');
      return null;
    }
  }

  /// 查找相似题目
  Future<List<Question>> findSimilarQuestions(String content, {int limit = 5}) async {
    try {
      List<Question> similarQuestions = [];
      
      // 从Hive查找
      final questions = _questionsBox?.values.toList() ?? [];
      for (final question in questions) {
        double similarity = _textParser.calculateSimilarity(content, question.content);
        if (similarity > 0.5) {
          similarQuestions.add(question);
        }
      }

      // 按相似度排序
      similarQuestions.sort((a, b) {
        double simA = _textParser.calculateSimilarity(content, a.content);
        double simB = _textParser.calculateSimilarity(content, b.content);
        return simB.compareTo(simA);
      });

      return similarQuestions.take(limit).toList();
    } catch (e) {
      print('查找相似题目失败: $e');
      return [];
    }
  }

  /// 根据题干内容和题型查找相似题目（模糊匹配）
  Future<List<Question>> findSimilarQuestionsByType(String content, QuestionType type, {int limit = 5}) async {
    try {
      List<Question> similarQuestions = [];
      
      // 从Hive查找同类型题目
      final questions = _questionsBox?.values.toList() ?? [];
      for (final question in questions) {
        if (question.type == type) {
          double similarity = _textParser.calculateSimilarity(content, question.content);
          if (similarity > 0.5) {
            similarQuestions.add(question);
            print('🔍 找到相似题目 (相似度: ${(similarity * 100).toStringAsFixed(1)}%): ${question.content.substring(0, 30)}...');
          }
        }
      }

      // 按相似度排序
      similarQuestions.sort((a, b) {
        double simA = _textParser.calculateSimilarity(content, a.content);
        double simB = _textParser.calculateSimilarity(content, b.content);
        return simB.compareTo(simA);
      });

      final result = similarQuestions.take(limit).toList();
      print('📊 在${_getTypeDisplayName(type)}中找到${result.length}个相似题目');
      return result;
    } catch (e) {
      print('❌ 根据题型查找相似题目失败: $e');
      return [];
    }
  }

  /// 获取题目类型的显示名称
  String _getTypeDisplayName(QuestionType type) {
    switch (type) {
      case QuestionType.single:
        return '单选题';
      case QuestionType.multiple:
        return '多选题';
      case QuestionType.judge:
        return '判断题';
    }
  }

  /// 关键词搜索题目
  Future<List<Question>> searchQuestionsByKeywords(String keywords) async {
    try {
      // 如果是Web平台，使用Hive进行搜索
      if (kIsWeb || _database == null) {
        final questions = _questionsBox?.values.toList() ?? [];
        final results = questions.where((question) {
          return question.content.toLowerCase().contains(keywords.toLowerCase());
        }).toList();
        
        // 按使用次数和创建时间排序
        results.sort((a, b) {
          int compareUsage = b.usageCount.compareTo(a.usageCount);
          if (compareUsage != 0) return compareUsage;
          return b.createdAt.compareTo(a.createdAt);
        });
        
        return results.take(10).toList();
      }

      // 非Web平台使用SQLite搜索
      final List<Map<String, dynamic>> maps = await _database!.rawQuery(
        'SELECT * FROM questions WHERE content LIKE ? ORDER BY usage_count DESC, created_at DESC LIMIT 10',
        ['%$keywords%'],
      );

      return maps.map((map) => _mapToQuestion(map)).toList();
    } catch (e) {
      print('关键词搜索失败: $e');
      return [];
    }
  }

  /// 获取所有题目
  Future<List<Question>> getAllQuestions({int? limit, int? offset}) async {
    try {
      // 如果是Web平台，使用Hive
      if (kIsWeb || _database == null) {
        List<Question> questions = _questionsBox?.values.toList() ?? [];
        
        // 按创建时间倒序排序
        questions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // 应用分页
        if (offset != null) {
          questions = questions.skip(offset).toList();
        }
        if (limit != null) {
          questions = questions.take(limit).toList();
        }
        
        return questions;
      }

      // 非Web平台使用SQLite
      String sql = 'SELECT * FROM questions ORDER BY created_at DESC';
      List<dynamic> args = [];
      
      if (limit != null) {
        sql += ' LIMIT ?';
        args.add(limit);
        
        if (offset != null) {
          sql += ' OFFSET ?';
          args.add(offset);
        }
      }

      final List<Map<String, dynamic>> maps = await _database!.rawQuery(sql, args);
      return maps.map((map) => _mapToQuestion(map)).toList();
    } catch (e) {
      print('获取题目列表失败: $e');
      return [];
    }
  }

  /// 更新题目使用次数
  Future<void> updateQuestionUsage(String questionId) async {
    try {
      // 更新Hive中的数据
      final question = _questionsBox?.get(questionId);
      if (question != null) {
        question.usageCount++;
        question.lastUsedAt = DateTime.now();
        await _questionsBox?.put(questionId, question);
      }

      // 更新SQLite（仅非Web平台）
      if (!kIsWeb && _database != null) {
        await _database!.update(
          'questions',
          {
            'usage_count': question?.usageCount ?? 1,
            'last_used_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [questionId],
        );
      }
    } catch (e) {
      print('更新题目使用次数失败: $e');
    }
  }

  /// 更新题目
  Future<void> updateQuestion(Question question) async {
    try {
      await _questionsBox?.put(question.id, question);
      
      // 更新SQLite（仅非Web平台）
      if (!kIsWeb && _database != null) {
        await _database!.update(
          'questions',
          _questionToMap(question),
          where: 'id = ?',
          whereArgs: [question.id],
        );
      }
    } catch (e) {
      print('更新题目失败: $e');
    }
  }

  /// 删除题目
  Future<void> deleteQuestion(String questionId) async {
    try {
      await _questionsBox?.delete(questionId);
      
      // 删除SQLite记录（仅非Web平台）
      if (!kIsWeb && _database != null) {
        await _database!.delete(
          'questions',
          where: 'id = ?',
          whereArgs: [questionId],
        );
      }
    } catch (e) {
      print('删除题目失败: $e');
    }
  }

  // === 错题相关操作 ===

  /// 添加错题
  Future<void> addWrongQuestion(Question question, List<String> userAnswers) async {
    try {
      final wrongQuestion = WrongQuestion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        question: question,
        userAnswers: userAnswers,
        wrongTime: DateTime.now(),
        wrongCount: 1,
      );

      // 检查是否已存在
      final existing = await _findExistingWrongQuestion(question.id);
      if (existing != null) {
        // 更新错题次数
        existing.wrongCount++;
        existing.lastWrongTime = DateTime.now();
        await _wrongQuestionsBox?.put(existing.id, existing);
        
        // 更新SQLite（仅非Web平台）
        if (!kIsWeb && _database != null) {
          await _database!.update(
            'wrong_questions',
            _wrongQuestionToMap(existing),
            where: 'id = ?',
            whereArgs: [existing.id],
          );
        }
      } else {
        // 新增错题
        await _wrongQuestionsBox?.put(wrongQuestion.id, wrongQuestion);
        
        // 插入SQLite（仅非Web平台）
        if (!kIsWeb && _database != null) {
          await _database!.insert(
            'wrong_questions',
            _wrongQuestionToMap(wrongQuestion),
          );
        }
      }

      print('✅ 错题记录成功');
    } catch (e) {
      print('❌ 错题记录失败: $e');
    }
  }

  /// 查找已存在的错题
  Future<WrongQuestion?> _findExistingWrongQuestion(String questionId) async {
    try {
      final wrongQuestions = _wrongQuestionsBox?.values.toList() ?? [];
      for (final wq in wrongQuestions) {
        if (wq.question.id == questionId) {
          return wq;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 获取所有错题
  Future<List<WrongQuestion>> getAllWrongQuestions() async {
    try {
      final wrongQuestions = _wrongQuestionsBox?.values.toList() ?? [];
      wrongQuestions.sort((a, b) => b.wrongTime.compareTo(a.wrongTime));
      return wrongQuestions;
    } catch (e) {
      print('获取错题列表失败: $e');
      return [];
    }
  }

  /// 删除错题
  Future<void> deleteWrongQuestion(String wrongQuestionId) async {
    try {
      await _wrongQuestionsBox?.delete(wrongQuestionId);
      
      // 删除SQLite记录（仅非Web平台）
      if (!kIsWeb && _database != null) {
        await _database!.delete(
          'wrong_questions',
          where: 'id = ?',
          whereArgs: [wrongQuestionId],
        );
      }
    } catch (e) {
      print('删除错题失败: $e');
    }
  }

  /// 清空错题库
  Future<void> clearWrongQuestions() async {
    try {
      await _wrongQuestionsBox?.clear();
      
      // 清空SQLite表（仅非Web平台）
      if (!kIsWeb && _database != null) {
        await _database!.delete('wrong_questions');
      }
    } catch (e) {
      print('清空错题库失败: $e');
    }
  }

  // === 统计相关操作 ===

  /// 获取统计数据
  Future<Map<String, int>> getStatistics() async {
    try {
      final totalQuestions = _questionsBox?.length ?? 0;
      final totalWrongQuestions = _wrongQuestionsBox?.length ?? 0;
      
      // 计算正确率
      int totalUsage = 0;
      final questions = _questionsBox?.values.toList() ?? [];
      for (final question in questions) {
        totalUsage += question.usageCount;
      }
      
      final accuracy = totalUsage > 0 
          ? ((totalUsage - totalWrongQuestions) / totalUsage * 100).round()
          : 0;

      return {
        'totalQuestions': totalQuestions,
        'totalWrongQuestions': totalWrongQuestions,
        'accuracy': accuracy,
        'totalUsage': totalUsage,
      };
    } catch (e) {
      print('获取统计数据失败: $e');
      return {
        'totalQuestions': 0,
        'totalWrongQuestions': 0,
        'accuracy': 0,
        'totalUsage': 0,
      };
    }
  }

  // === 数据转换方法 ===

  /// Question转Map
  Map<String, dynamic> _questionToMap(Question question) {
    return {
      'id': question.id,
      'number': question.number,
      'type': question.type.name,
      'content': question.content,
      'options': question.options.join('|'),
      'correct_answers': question.correctAnswers.join('|'),
      'image_url': question.imageUrl,
      'created_at': question.createdAt.millisecondsSinceEpoch,
      'last_used_at': question.lastUsedAt?.millisecondsSinceEpoch,
      'usage_count': question.usageCount,
      'confidence': question.confidence,
      'answer_source': question.answerSource.name,
    };
  }

  /// Map转Question
  Question _mapToQuestion(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      number: map['number'],
      type: QuestionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => QuestionType.single,
      ),
      content: map['content'],
      options: map['options'].split('|'),
      correctAnswers: map['correct_answers'].split('|'),
      imageUrl: map['image_url'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      lastUsedAt: map['last_used_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['last_used_at'])
          : null,
      usageCount: map['usage_count'] ?? 0,
      confidence: map['confidence'] ?? 0.0,
      answerSource: AnswerSource.values.firstWhere(
        (e) => e.name == map['answer_source'],
        orElse: () => AnswerSource.database,
      ),
    );
  }

  /// WrongQuestion转Map
  Map<String, dynamic> _wrongQuestionToMap(WrongQuestion wrongQuestion) {
    return {
      'id': wrongQuestion.id,
      'question_id': wrongQuestion.question.id,
      'user_answers': wrongQuestion.userAnswers.join('|'),
      'wrong_time': wrongQuestion.wrongTime.millisecondsSinceEpoch,
      'wrong_count': wrongQuestion.wrongCount,
      'last_wrong_time': wrongQuestion.lastWrongTime?.millisecondsSinceEpoch,
      'note': wrongQuestion.note,
    };
  }

  /// 关闭数据库
  Future<void> dispose() async {
    await _questionsBox?.close();
    await _wrongQuestionsBox?.close();
    await _database?.close();
  }
} 