# openlist-lzcapp

每天 23:00 UTC 检查 `openlistteam/openlist` 的 `vX.Y.Z-aio` 稳定版本，映射为 `X.Y.Z`，自动复制 `linux/amd64` 镜像、创建版本化 LPK Release，并提交懒猫官方商店和喵喵私有商店。

需要显式配置 `LAZYCAT_TOKEN`、`APPSTORE_URL`、`APPSTORE_TOKEN`；`APP_ID` 和 `PRIVATE_STORE_GROUP_CODES` 可选。组织 Secret 必须授权本仓库。
