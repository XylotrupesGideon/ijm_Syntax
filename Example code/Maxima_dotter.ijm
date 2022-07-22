/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix
#@ Integer (label = "Dot radius", value = 5) radius
#@ Integer (label = "Maxima prominence", value = 350) prominence

setBatchMode(true);
processFolder(input);
print("DONE :)")
setBatchMode(false);
// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	
	}
}

function processFile(input, output, file) {
	//opening file
		// Leave the print statements until things work, then remove them.
	print("Processing: " + input + File.separator + file);
	run("Bio-Formats Importer", "open=["+ input + File.separator + file + "] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");	
	run("Duplicate...", "title=duplicate duplicate");
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel"); // the scaling interferes with the x and y coordinates
	run("Split Channels");
	run("Find Maxima...", "prominence=" + prominence + " output=[Point Selection]"); // find maxima of red channel
	run("Measure"); // get X and y coordinates

// create a new slice with the same size as a duplicate of a image slice
	run("Duplicate...", "title=dots");
	run("Select All");
	setBackgroundColor(0, 0, 0);
	run("Clear", "slice"); // clears the new slice

//All your points are in the results table to manipulate as you will
	X=newArray(nResults);
	Y=newArray(nResults);

	for(i=0;i<nResults;i++){
		X[i]=getResult("X",i);
		Y[i]=getResult("Y",i);
	}

	for(i=0;i<nResults;i++){
		fillOval(X[i]-radius, Y[i]-radius, 2*radius, 2*radius); //darws an dot on each maxima
		run("Draw", "slice");
	}
	run("Select All");
	selectWindow(file); //go back to original file
	run("Split Channels"); 
	run("Merge Channels...", "c1=[C1-"+ file +"] c2=[C2-"+ file + "] c3=[C3-"+ file + "] c4=dots create ignore"); //add the new dot image as a channel
	print("Saving to: " + output);
	saveAs("Tiff",  output + File.separator + "DOTs_" + file + ".tif");
	run("Clear Results"); 
	roiManager("reset")
	//Close everything
	while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      } 
}
