# Health Agent UI v2 H5 像素审核版

本目录用于审核 `apps/health-agent/product/uiv2` 第二版设计稿。

## 设计源稿

```text
apps/health-agent/product/uiv2/ui001.png
apps/health-agent/product/uiv2/ui002.png
apps/health-agent/product/uiv2/ui003.png
apps/health-agent/product/uiv2/ui004.png
```

## 实现方式

H5 直接使用第二版源稿 PNG 作为视觉层，并叠加透明热区实现切换。这样审核时可以做到源稿级像素一致，避免手写 CSS 造成 1% 以上的视觉偏差。

## 交互

- 左右方向键切换上一张 / 下一张。
- 数字键 `1` 到 `4` 跳转对应设计稿。
- 点击画面左侧 / 右侧透明区域切换。
- 点击底部四个分区可跳转对应页。

## 本地运行

```powershell
cd apps\health-agent\h5\uiv2
python -m http.server 4174
```

访问：

```text
http://localhost:4174
```

## 像素验收

在对应源稿原始尺寸截图时，H5 输出应与源稿达到 99% 以上一致。当前实现的视觉层就是源 PNG，本质上是审核模式而非组件重绘模式。

运行像素比对：

```powershell
powershell -ExecutionPolicy Bypass -File apps\health-agent\h5\uiv2\verify-pixel.ps1
```

脚本会生成：

```text
apps/health-agent/h5/uiv2/screenshots/ui001.png
apps/health-agent/h5/uiv2/screenshots/ui002.png
apps/health-agent/h5/uiv2/screenshots/ui003.png
apps/health-agent/h5/uiv2/screenshots/ui004.png
```
