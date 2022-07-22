/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	first = true
	setBatchMode(true);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			first = processFolder(input + File.separator + list[i],i);
		if(endsWith(list[i], suffix))
			first = processFile(input, output, list[i],i);
	}
	setBatchMode(false);
	print("DONE");
}

function processFile(input, output, file,i) {
	if (first == true){
		run("Bio-Formats Importer", "open=[" + input + File.separator + file + "] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		
	}
	else {
		previous = getTitle();
		run("Bio-Formats Importer", "open=[" + input + File.separator + file + "] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		current = getTitle();
		run("Pairwise stitching", "first_image=[" + previous + "] second_image=[" + current + "] fusion_method=[Linear Blending] fused_image=stitch.nd2 check_peaks=5 compute_overlap x=0.0000 y=0.0000 z=0.0000 registration_channel_image_1=[Average all channels] registration_channel_image_2=[Average all channels]");		
		saveAs("Tiff", output + File.separator + "stitch_temp_"+ i + ".tif");
	}
	return false;
	}


