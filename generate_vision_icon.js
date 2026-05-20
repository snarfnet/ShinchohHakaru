const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const width = 1024;
const height = 1024;
const output = process.argv[2] || 'C:\\Users\\Windows\\ShiryokuCheck\\ShiryokuCheck\\Assets.xcassets\\AppIcon.appiconset\\icon_1024.png';

const bgTop = [0xd6, 0xea, 0xf8, 0xff];
const bgBottom = [0xff, 0xff, 0xff, 0xff];
const ring = [0x1a, 0x52, 0x76, 0xff];
const centerX = 512;
const centerY = 512;
const outerRadius = 360;
const innerRadius = 260;
const gapHalfAngle = 25;
const samples = [
  [0.25, 0.25],
  [0.75, 0.25],
  [0.25, 0.75],
  [0.75, 0.75],
];

function lerp(a, b, t) {
  return Math.round(a + (b - a) * t);
}

function bgColor(y) {
  const t = y / (height - 1);
  return [
    lerp(bgTop[0], bgBottom[0], t),
    lerp(bgTop[1], bgBottom[1], t),
    lerp(bgTop[2], bgBottom[2], t),
    0xff,
  ];
}

function isRingPixel(x, y) {
  const dx = x - centerX;
  const dy = y - centerY;
  const radius = Math.sqrt(dx * dx + dy * dy);
  if (radius < innerRadius || radius > outerRadius) return false;

  let angle = Math.atan2(dy, dx) * 180 / Math.PI;
  if (angle < 0) angle += 360;

  return angle >= gapHalfAngle && angle <= 360 - gapHalfAngle;
}

function makePng() {
  const stride = width * 4 + 1;
  const raw = Buffer.alloc(stride * height);

  for (let y = 0; y < height; y++) {
    const row = y * stride;
    raw[row] = 0;

    for (let x = 0; x < width; x++) {
      const base = bgColor(y);
      let coverage = 0;

      for (const [sx, sy] of samples) {
        if (isRingPixel(x + sx, y + sy)) coverage++;
      }

      const alpha = coverage / samples.length;
      const offset = row + 1 + x * 4;
      raw[offset] = Math.round(base[0] * (1 - alpha) + ring[0] * alpha);
      raw[offset + 1] = Math.round(base[1] * (1 - alpha) + ring[1] * alpha);
      raw[offset + 2] = Math.round(base[2] * (1 - alpha) + ring[2] * alpha);
      raw[offset + 3] = 0xff;
    }
  }

  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr()),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

function ihdr() {
  const data = Buffer.alloc(13);
  data.writeUInt32BE(width, 0);
  data.writeUInt32BE(height, 4);
  data[8] = 8;
  data[9] = 6;
  data[10] = 0;
  data[11] = 0;
  data[12] = 0;
  return data;
}

function chunk(type, data) {
  const typeBuffer = Buffer.from(type, 'ascii');
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length, 0);

  const crcBuffer = Buffer.alloc(4);
  crcBuffer.writeUInt32BE(crc(Buffer.concat([typeBuffer, data])), 0);

  return Buffer.concat([length, typeBuffer, data, crcBuffer]);
}

const crcTable = (() => {
  const table = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) {
      c = (c & 1) ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    }
    table[n] = c >>> 0;
  }
  return table;
})();

function crc(buffer) {
  let c = 0xffffffff;
  for (let i = 0; i < buffer.length; i++) {
    c = crcTable[(c ^ buffer[i]) & 0xff] ^ (c >>> 8);
  }
  return (c ^ 0xffffffff) >>> 0;
}

fs.mkdirSync(path.dirname(output), { recursive: true });
fs.writeFileSync(output, makePng());

const stats = fs.statSync(output);
console.log(`${output}`);
console.log(`${stats.size}`);
