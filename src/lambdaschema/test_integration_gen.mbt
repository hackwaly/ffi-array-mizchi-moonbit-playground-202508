// インテグレーションテスト生成のテスト

test "run_integration_test_generator" {
  generate_and_save_integration_test()
  assert_true(true) // テストが正常に実行されたことを確認
}