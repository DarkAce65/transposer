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
String[] letteredKeys = {" A", "A#", " B", " C", "C#", " D", "D#", " E", " F", "F#", " G", "G#"};
float[] spectrum = new float[sampleSize];
float[] amp = new float[3];
float[] freq = new float[3];
String[] keys = new String[3];

String setDec(float v, int d) {
	float a = pow(10, d);
	return str(floor(v * a) / a);
}

float RA(float f) {
	return pow(12194, 2) * pow(f, 4) / ((pow(f, 2) + pow(20.6, 2)) * sq((pow(f, 2) + pow(107.7, 2)) * (pow(f, 2) + pow(737.9, 2))) * (pow(f, 2) + pow(12194, 2)));
}

float AWeighting(float f) {
	return 20 * log(RA(f)) + 2;
}

int keyN(float frequency) {
	return floor(12 * log(frequency / 440) / log(2)) + 49;
}

String pianoKey(int keyN) {
	if(keyN < 1 || keyN > 88) {
		return "---";
	}
	return letteredKeys[(keyN - 1) % 12] + floor((keyN + 8) / 12);
}

void setup() {
	surface.setSize(w, h + 70);
	background(0);
	textFont(createFont("iosevka-regular.ttf", 12));

	minim = new Minim(this);
	ain = minim.getLineIn(Minim.MONO, sampleSize);

	fft = new FFT(ain.bufferSize(), ain.sampleRate());
}

void draw() {
	fft.forward(ain.mix);

	int[] max = new int[3];
	for (int i = 0; i < sampleSize; i++) {
		spectrum[i] = fft.getBand(i);// * AWeighting(fft.indexToFreq(i));
		if(spectrum[max[0]] < spectrum[i]) {
			max[2] = max[1];
			max[1] = max[0];
			max[0] = i;
		}
		else if(spectrum[max[1]] < spectrum[i]) {
			max[2] = max[1];
			max[1] = i;
		}
		else if(spectrum[max[2]] < spectrum[i]) {
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

		amp[i] = spectrum[max[i]];
		freq[i] = fft.indexToFreq(max[i]);
		keys[i] = pianoKey(keyN(freq[i]));
	}

	fill(64);
	noStroke();
	rect(0, h, width, 70);
	fill(255);
	text("Largest Amplitudes: " + setDec(amp[0], 3) + ", " + setDec(amp[1], 3) + ", " + setDec(amp[2], 3), 0, height - 50);
	text("Largest Frequencies: " + setDec(freq[0], 3) + ", " + setDec(freq[1], 3) + ", " + setDec(freq[2], 3), 0, height - 30);
	text("Piano Keys: " + keys[0] + ", " + keys[1] + ", " + keys[2], 0, height - 10);

	x++;
	if(x > width) {
		x = 0;
		y = (y + 1) % 2;
	}
}
