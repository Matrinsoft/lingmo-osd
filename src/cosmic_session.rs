// Copyright 2023 System76 <info@system76.com>
// SPDX-License-Identifier: GPL-3.0-only

use zbus::proxy;

#[proxy(
    interface = "com.lingmoos.LingmoSession",
    default_service = "com.lingmoos.LingmoSession",
    default_path = "/com/lingmoos/LingmoSession"
)]
pub trait CosmicSession {
    fn exit(&self) -> zbus::Result<()>;
}
