import ddf.minim.*;
import ddf.minim.analysis.*;

int sampleRate = 44100;
int sampleSize = 4096;
Minim minim;
AudioInput ain;
FFT fft;

int w = 700;
int h = 500;
int x = 0;
int y = 1;
String[] letteredKeys = {"A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"};
float[] amp = new float[3];
float[] freq = new float[3];
String[] keys = new String[3];

int keyN(float frequency) {
	return floor(12 * log(frequency / 440) / log(2)) + 49;
}

String pianoKey(int keyN) {
	if(keyN < 1) {
		return "NaN";
	}
	return letteredKeys[(keyN - 1) % 12] + floor((keyN + 8) / 12);
}

void setup() {
	surface.setSize(w, h + 70);
	background(0);

	minim = new Minim(this);
	ain = minim.getLineIn(Minim.MONO, sampleSize);

	fft = new FFT(ain.bufferSize(), ain.sampleRate());
}

void draw() {
	fft.forward(ain.mix);

	int[] max = new int[3];
	for (int i = 0; i < sampleSize; i++) {
		float v = fft.getBand(i);
		if(fft.getBand(max[0]) < v) {
			max[2] = max[1];
			max[1] = max[0];
			max[0] = i;
		}
		else if(fft.getBand(max[1]) < v) {
			max[2] = max[1];
			max[1] = i;
		}
		else if(fft.getBand(max[2]) < v) {
			max[2] = i;
		}
	}

	if(x < width / 10) {
		fill(0);
		noStroke();
		rect(x * 10, (1 - y) * h / 2, 10, h / 2);
	}
	
	for(int i = max.length - 1; i >= 0; i--) {
		stroke(i == 0 ? 255 : 64);
		float py = max(1, min(88, keyN(freq[i]))) * h / 88 / 2;
		float ny = max(1, min(88, keyN(fft.indexToFreq(max[i])))) * h / 88 / 2;
		line(x - 1, h - py - y * h / 2, x, h - ny - y * h / 2);
		
		amp[i] = fft.getBand(max[i]);
		freq[i] = fft.indexToFreq(max[i]);
		keys[i] = pianoKey(keyN(freq[i]));
	}
	
	fill(64);
	noStroke();
	rect(0, h, width, 70);
	fill(255);
	text("Largest Amplitudes: " + amp[0] + ", " + amp[1] + ", " + amp[2], 0, height - 50);
	text("Largest Frequencies: " + freq[0] + ", " + freq[1] + ", " + freq[2], 0, height - 30);
	text("Piano Keys: " + keys[0] + ", " + keys[1] + ", " + keys[2], 0, height - 10);

	x++;
	if(x > width) {
		x = 0;
		y = (y + 1) % 2;
	}
}