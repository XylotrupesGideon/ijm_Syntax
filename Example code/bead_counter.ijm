#@ File (label = "Input directory", style = "directory") input
#@ String (label = "File suffix", value = ".nd2") suffix



processFolder(input);
print("DONE :)");

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	output = input + File.separator + "Output";
	File.makeDirectory(output)
	if (File.exists(output + File.separator + "output.txt")){
		File.delete(output + File.separator + 'output.txt');
	}
	file=File.open(output + File.separator + "output.txt");
	print(file, "FileMane\tTotalArea\tGFPArea\t%GFPArea\tMeanSignal\ttotalBeads\tinternal\t%internal\texternal\t%external\tpartial\t%partial\n");
	File.makeDirectory(output + File.separator + "ROIs");
	for (i = 0; i < list.length; i++) {
		if (i%2 == 0){//only every second file
			if(File.isDirectory(input + File.separator + list[i]))
				processFolder(input + File.separator + list[i]);
			if(endsWith(list[i], suffix))
				thresholds = thresholding(list[i+1]);		
				print(list[i],list[i+1]);
				if (i+1 > list.length || startsWith(list[i+1], "Output") || startsWith(list[i], "Output")){}
				else{
					processFile(i,input, output, list[i],list[i+1],file,thresholds);
				}
		}
	}
	File.close(file)
}

function GFP_Area(cell_file,input, output, CellROIs_path,file,upper,lower){
	//resets all results
	run("Clear Results");
	roiManager("reset");
	print("Area Calculation in:"+ input + File.separator + cell_file);
	//open image
	run("Bio-Formats Importer", "open=["+ input + File.separator + cell_file + "]");
	run("Duplicate...", "title=mask");
	print(upper+";"+lower);
	setThreshold(calibrate(lower), calibrate(upper),"raw");
	run("Convert to Mask");
	selectWindow("mask");
	run("Fill Holes");
	//implement Optional cell size control
	run("Analyze Particles...", "size=100-Infinity add"); //gets selections for each shape
	roiManager("Save", CellROIs_path);//saves ROIS 
	print("Saved cell area ROIS in: " + CellROIs_path);
	run("Duplicate...", "title=cell_area");
	run("Select All");
	run("Measure");
	totalArea=getResult("Area",0);
	run("Clear", "slice");
	run("Select None");
	selectWindow("cell_area");
	roiManager("show all");
	roiManager("draw");
	selectWindow(cell_file);
	run("Clear Results");
	roiManager("show all");
	roiManager("measure"); // measures signal intensity in the original image
	Area=0;
	Means=0;
	for (i=0;i<nResults;i++){
		Area=Area+getResult("Area",i);
		Means=Means+getResult("Mean",i);
		}
	MeanSignal=Means/nResults;
	print("Area: " + Area +"\t\tMeanSignal: "+ MeanSignal);
	return newArray(Area, MeanSignal,totalArea,upper,lower);
}

function count_beads(bead_file,BeadROIs_path,file){
	run("Clear Results");
	roiManager("reset");
	print("Counting beads in: "+ bead_file);
	run("Bio-Formats Importer", "open=["+ input + File.separator + bead_file + "] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	run("Gaussian Blur...", "sigma=2");// blurs image to get rid of background
	run("Find Maxima...", "prominence=10 output=[Single Points]"); //finds maxima (center of beads) and draws a new image with single pixles
	run("Analyze Particles...", "size=0-Infinity display");//counts those pixles
	selectWindow("mask"); // the mask image is 0 (black) when the bead is internal and 255 (white) when it is external
	//create image copies to draw bead selection
	run("Duplicate..." ,"title=internal_breads");
	run("Select All");
	run("Clear", "slice");
	run("Select None");
	run("Duplicate..." ,"title=external_breads");
	run("Duplicate..." ,"title=partial_breads");
	//get x and y coords of bead centers
	X = newArray(nResults); //new array for x coords
	Y = newArray(nResults); //new array for y coords
	totalBeads = nResults; // number of beads in total
	for (i=0;i<nResults;i++){ //iterate over point coordinates
		X[i]=getResult("XM",i); //fill array
		Y[i]=getResult("YM",i); //fill array
		toUnscaled(X[i]); //scaling
		toUnscaled(Y[i]); //scaling
		makeOval( X[i]-11,Y[i]-11, 2 * 11, 2 * 11); //draws a selection on each maxima
		roiManager("Add"); // populates ROI manager	
	}
	run("Clear Results");//clear point roi measurments
	roiManager("Save", BeadROIs_path);
	print("Saved bead area ROIS in: " + BeadROIs_path);
	selectWindow("mask");
	roiManager("Show All");
	roiManager("Measure"); //measurement of the bead sized selection
	internal = 0; //amount internal beads
	partial = 0; //amount partial beads (overlapping of membrane associated)
	external = 0;//amount external beads
	Means = newArray(nResults); //Mean in mask image should be between 0 and 255 depending on how internal the bead is
	nRois=roiManager("count");
	res=nResults;
	for (i=0;i<nResults;i++){// iterates over measurments of beads
		Means[i] = getResult("Mean",i); //extracts mean
		if (Means[i] == 0){ //if the whole bead is on the black area (internal)
			internal++; // add 1 to internal
			selectWindow("internal_breads"); //selects the requred image file
			roiManager("select", i); //selects the current bead selection from roi manager
			roiManager("draw");
			}
		else if (Means[i] == 255){//if the mean is white (completely external)
			external++;
			selectWindow("external_breads");
			roiManager("select", i);
			roiManager("draw");
		}
		else { //else partial
			partial++;
			selectWindow("partial_breads");
			roiManager("select", i);
			roiManager("draw");
		} 
	}
	return newArray(totalBeads,internal,external,partial);
}

function thresholding(image){
	setBatchMode(false);
	run("Bio-Formats Importer", "open=["+ input + File.separator + image + "]");
	run("Threshold...");  // open Threshold tool
	waitForUser("Thresholding", "Choose an appropriate threshold");
	//setBatchMode(true);
	getThreshold(lower, upper);
	if (lower==-1)
      exit("Threshold was not set");
    else{
    	close();
    	return newArray(upper,lower)
    	}
	}



function processFile(i,input, output, bead_file, cell_file,file,thresholds) {
	run("Line Width...", "line=5");
	setForegroundColor(255,255,255);
	BeadROIs_path =  output + File.separator + "ROIs" + File.separator + substring(cell_file, 0, 3) + "_bead_rois.zip";
	CellROIs_path = output + File.separator + "ROIs" + File.separator + substring(cell_file, 0, 3) + "_cell_rois.zip";
	gfp_measure = GFP_Area(cell_file,input, output, CellROIs_path,file,thresholds[0],thresholds[1]);
	Area = gfp_measure[0];
	MeanSignal = gfp_measure[1];
	totalArea = gfp_measure[2];
	bead_measure = count_beads(bead_file,BeadROIs_path,file);
	totalBeads = bead_measure[0];
	internal = bead_measure[1];
	external = bead_measure[2];
	partial = bead_measure[3];
	print("Saved output");
	print(file,cell_file + "\t"+totalArea +"\t"+ d2s(Area,2) + "\t" + d2s(Area/totalArea*100,2) +"\t"+ d2s(MeanSignal,2)+ "\t" + totalBeads + "\t" + internal + "\t" + d2s(internal/totalBeads*100,2) + "\t " + external + "\t" + d2s(external/totalBeads*100,2) + "\t"+ partial + "\t" + d2s(partial/totalBeads*100,2) + "\n");
	print("Generating check up image:");
	selectWindow("mask");
	close();
	selectWindow(bead_file + " Maxima");
	close();
	selectWindow(bead_file);
	run("8-bit");
	selectWindow(cell_file);
	run("8-bit");
	run("Images to Stack", "name=Checkup_image title=[] use");
	run("Make Composite", "display=Composite");
	saveAs("Tiff", output + File.separator + substring(cell_file, 0, 3) + "_checkup.tif");
	}