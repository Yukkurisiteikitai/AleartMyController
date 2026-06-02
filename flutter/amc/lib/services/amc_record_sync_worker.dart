// TODO(P4): DB 同期 worker（migration_plan.md §4.3）。
// 順序厳守: amc_records upsert → revisions insert → attachments insert
//          → ローカルファイル削除 → markRecordSynced。
