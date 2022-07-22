/*
 * Macro template to process multiple images in a folder
 */

#@ File (label = "Input directory", style = "directory") input
#@ String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.
setBatchMode(true);
processFolder(input);

setBatchMode(false);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, list[i]);
	}
}

function processFile(input, file) {
	print("Processing: " + input + File.separator + file);
	run("Bio-Formats Importer", "open=["+ input + File.separator + file +"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	run("Z Project...", "projection=[Max Intensity]");
	run("Make Composite");
	print("Saving: " + "["+input+ File.separator + "MAX_Comp_"+file+".tif]");
	saveAs("Tiff", ""+input+ File.separator + "MAX_Comp_"+ file + ".tif");
	while(nImages >0){
		close();
		}
}
