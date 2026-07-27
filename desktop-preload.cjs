const { contextBridge } = require('electron');

contextBridge.exposeInMainWorld('phoenixDesktop', {
  platform: process.platform,
  version: '3.1.0'
});
