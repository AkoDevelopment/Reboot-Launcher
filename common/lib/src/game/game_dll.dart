enum GameDll {
  console,
  auth,
  gameServer,
  memoryLeak,
  editOnRelease
}

extension InjectableDllVersionAware on GameDll {
  bool get isVersionDependent => this == GameDll.gameServer;
}
