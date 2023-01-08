PImage img;

int KERNEL_SIDE = 6;
void settings() {
  img = loadImage("Images/lion.jpeg");
  size(img.width, img.height);
}


void setup() {
  //image(img, 0, 0);
  PImage result = simpleKuwahara(img, KERNEL_SIDE);
  image(result, 0, 0);
}

PImage simpleKuwahara(PImage img, int kernelSide) {
  // kernelSide is used to set the size of the kernel for the filter
  // it is used in the following calculation: kernelSize = 2 * kernelSide + 1
  PImage result = createImage(img.width, img.height, RGB);


  for (int i = kernelSide; i < (img.width - kernelSide); i++) {
    for (int j = kernelSide; j < (img.height - kernelSide); j++) {
      color c = computeKuwahara(i, j, kernelSide, img);
      result.pixels[(j) * result.width + (i)] = c;
    }
  }

  return result;
}

color computeKuwahara(int i, int j, int kernelSide, PImage img) {
  // The kernel must be divided into 4 overlapping squares.
  // 1) (i-kernelLength, j-kernelLength) to (i, j)
  // 2) (i, j-kernelLength) to (i+kernelLength, j)
  // 3) (i-kernelLength, j) to (i, j+kernelLength)
  // 4) (i, j) to (i+kernelLength, j+kernelLength)
  // For each section, the standard deviation will be computed, using the brightness of the pixels as the parameter
  // The pixel in (i, j) will be the average color of the quadrant with the lowest std

  int qSide = kernelSide + 1;
  int qSize = int(pow(qSide, 2));

  color[] q1 = new color[qSize];
  color[] q2 = new color[qSize];
  color[] q3 = new color[qSize];
  color[] q4 = new color[qSize];

  int[] q1Ind = new int[qSize];
  int[] q2Ind = new int[qSize];
  int[] q3Ind = new int[qSize];
  int[] q4Ind = new int[qSize];

  float q1Total = 0;
  float q2Total = 0;
  float q3Total = 0;
  float q4Total = 0;

  color[] pxs = img.pixels;

  for (int x = 0; x < qSide; x++) {
    for (int y = 0; y < qSide; y++) {
      int q1Index = (j - kernelSide + y) * img.width + (i - kernelSide + x);
      int q2Index = (j - kernelSide + y) * img.width + (i + x);
      int q3Index = (j + y) * img.width + (i - kernelSide + x);
      int q4Index = (j + y) * img.width + (i + x);

      q1Ind[y*qSide + x] = q1Index;
      q2Ind[y*qSide + x] = q2Index;
      q3Ind[y*qSide + x] = q3Index;
      q4Ind[y*qSide + x] = q4Index;

      q1[y*qSide + x] = int(brightness(pxs[q1Index]));
      q2[y*qSide + x] = int(brightness(pxs[q2Index]));
      q3[y*qSide + x] = int(brightness(pxs[q3Index]));
      q4[y*qSide + x] = int(brightness(pxs[q4Index]));

      q1Total += q1[y*qSide + x];
      q2Total += q2[y*qSide + x];
      q3Total += q3[y*qSide + x];
      q4Total += q4[y*qSide + x];
    }
  }

  float q1Mean = q1Total / qSize;
  float q2Mean = q2Total / qSize;
  float q3Mean = q3Total / qSize;
  float q4Mean = q4Total / qSize;


  float stds[] = new float[4]; // The standard deviations
  for (int k = 0; k < qSize; k++) {
    stds[0] += pow(q1[k] - q1Mean, 2);
    stds[1] += pow(q2[k] - q2Mean, 2);
    stds[2] += pow(q3[k] - q3Mean, 2);
    stds[3] += pow(q4[k] - q4Mean, 2);
  }

  for (int k = 0; k < 4; k++) {
    stds[k] = sqrt(stds[k]/qSize);
  }

  int winnerQuadrantNumber = indexOfMinStd(stds) + 1;
  int[] winnerIndices = null;
  color[] winnerQuadrant = null;
  switch (winnerQuadrantNumber) {
  case 1:
    winnerQuadrant = q1;
    winnerIndices = q1Ind;
    break;
  case 2:
    winnerQuadrant = q2;
    winnerIndices = q2Ind;
    break;
  case 3:
    winnerQuadrant = q3;
    winnerIndices = q3Ind;
    break;
  case 4:
    winnerQuadrant = q4;
    winnerIndices = q4Ind;
    break;
  default:
    throw new RuntimeException("Invalid queadrant number");
  }


  color[] colorQuadrant = new color[qSize];
  for (int k = 0; k < qSize; k++) {
    colorQuadrant[k] = img.pixels[winnerIndices[k]];
  }
  
  color finalColor = getAverageColor(colorQuadrant);
  return finalColor;
}

int indexOfMinStd(float stds[]) {
  float minSTD = min(stds);
  for (int i = 0; i < stds.length; i++) {
    if (minSTD == stds[i]) {
      return i;
    }
  }
  return -1;
}

color getAverageColor(color[] colors) {
   float r = 0.0, g = 0.0, b = 0.0;
   for (int i = 0; i < colors.length; i++) {
     color c = colors[i];
     r += red(c) * red(c);
     g += green(c) * green(c);
     b += blue(c) * blue(c);
   }
   
   return color(sqrt(r/colors.length), sqrt(g/colors.length), sqrt(b/colors.length));
}
