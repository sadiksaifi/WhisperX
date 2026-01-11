#!/usr/bin/env node

/**
 * Generates a DMG background image for WhisperX installer
 * Run: node scripts/generate-dmg-background.js
 * Requires: npm install canvas (in scripts directory)
 */

const { createCanvas } = require('canvas');
const fs = require('fs');
const path = require('path');

const WIDTH = 600;
const HEIGHT = 400;

const canvas = createCanvas(WIDTH, HEIGHT);
const ctx = canvas.getContext('2d');

// Background gradient (light gray, clean look)
const gradient = ctx.createLinearGradient(0, 0, 0, HEIGHT);
gradient.addColorStop(0, '#f5f5f7');
gradient.addColorStop(1, '#e8e8ed');
ctx.fillStyle = gradient;
ctx.fillRect(0, 0, WIDTH, HEIGHT);

// Subtle top highlight
ctx.fillStyle = 'rgba(255, 255, 255, 0.5)';
ctx.fillRect(0, 0, WIDTH, 1);

// Icon positions (matching create-dmg settings)
const appX = 150;
const appsX = 450;
const iconY = 185;

// Draw arrow between app and Applications
const arrowY = iconY;
const arrowStartX = appX + 60;
const arrowEndX = appsX - 60;

// Arrow line
ctx.strokeStyle = '#999999';
ctx.lineWidth = 2;
ctx.setLineDash([8, 4]);
ctx.beginPath();
ctx.moveTo(arrowStartX, arrowY);
ctx.lineTo(arrowEndX - 10, arrowY);
ctx.stroke();

// Arrow head
ctx.setLineDash([]);
ctx.fillStyle = '#999999';
ctx.beginPath();
ctx.moveTo(arrowEndX, arrowY);
ctx.lineTo(arrowEndX - 12, arrowY - 8);
ctx.lineTo(arrowEndX - 12, arrowY + 8);
ctx.closePath();
ctx.fill();

// "Drag to install" text
ctx.fillStyle = '#555555';
ctx.font = 'bold 17px Arial, Helvetica, sans-serif';
ctx.textAlign = 'center';
ctx.fillText('Drag to install', WIDTH / 2, arrowY + 40);

// Save to file
const outputDir = path.join(__dirname, 'dmg-resources');
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

const outputPath = path.join(outputDir, 'background.png');
const buffer = canvas.toBuffer('image/png');
fs.writeFileSync(outputPath, buffer);

console.log(`DMG background generated: ${outputPath}`);
console.log(`Dimensions: ${WIDTH}x${HEIGHT}`);
