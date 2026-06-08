/// dart:io の Web 用スタブ。
///
/// dart:io を条件付きインポートする Worker ファイルが Web でもコンパイルできるようにする。
/// kIsWeb ガードにより、実行時にはこのスタブのメソッドが呼ばれることはない。
class File {
  // ignore: avoid_unused_constructor_parameters
  const File(String path);

  bool existsSync() => false;

  Future<List<int>> readAsBytes() async => const <int>[];

  Future<File> delete({bool recursive = false}) async => this;
}
