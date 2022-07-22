
#@ File (label = "Input directory", style = "directory") input
#@ String (label = "File suffix", value = ".tif") suffix

processFolder(input);
print("DONE");
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
	Dialog.create("What operations to perform?");
	Dialog.addMessage("File:\n" + file)
	Dialog.addCheckbox("Add scale", true);
	Dialog.addNumber("microns/px: ", 0.62);
	Dialog.addNumber("microns/z-step: ", 1);
	Dialog.addCheckbox("Add scalebar", true);
	Dialog.addNumber("(If add scalebar) Scalebar size: ", 50);
	Dialog.addCheckbox("Maximum Project", true);
	Dialog.addCheckbox("3D Project", true);
	Dialog.show();
	set_scale		= Dialog.getCheckbox();
	micron_per_px 	= Dialog.getNumber();
	z_step 			= Dialog.getNumber();
	scale_bar		= Dialog.getCheckbox();
	scale_length	= Dialog.getNumber();
	maximum_project	= Dialog.getCheckbox();
	D_project		= Dialog.getCheckbox();
	setBatchMode(true);
	print("Processing: " + input + File.separator + file);
	run("Bio-Formats Importer", "open=[" + input + File.separator + file + "] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
	if (set_scale == true){
		run("Set Scale...", "distance=1 known="+ micron_per_px +" pixel=1 unit=µm");
		if (scale_bar == true) {
			run("Scale Bar...", "width="+ scale_length +" height=4 font=14 color=White background=None location=[Lower Right] bold overlay");
			}
		print("Save scaled image as:\n"+ input  + File.separator  + file);
		saveAs("Tiff", input  + File.separator  + file);
		file = getTitle(); //rename current file
	}
	getDimensions(width, height, channels, slices, frames);
	print("Detected "+ channels + " channels");
	channel_state = "";
	if (maximum_project == true){
		run("Z Project...", "projection=[Max Intensity]");
		run("Split Channels");
		for (i=1;i<=channels;i++){
			selectWindow("C"+ i + "-MAX_"+ file);
			getMinAndMax(min, max);
		  	print("Channel "+ i + " before: min=" + min + " max=" + max);
		  	run("Apply LUT");
		  	getMinAndMax(min, max);
		  	print("Channel "+ i + " after: min=" + min + " max=" + max);
		  	channel_state=channel_state + "c" + i + "=[C"+ i +"-MAX_"+ file + "] ";
		}
		run("Merge Channels...", channel_state + "create");
		if (scale_bar == true) {
			run("Scale Bar...", "width="+ scale_length +" height=4 font=14 color=White background=None location=[Lower Right] bold overlay");
			}
		//Saving maximum projection
		print("Saving maximum projection to: " + input + File.separator + "MAX_" + file);
		saveAs("Tiff", input  + File.separator + "MAX_" + file);
				
	}
	if (D_project == true){
		open(file);
		run("3D Project...", "projection=[Brightest Point] axis=Y-Axis slice=" + z_step + " initial=120 total=240 rotation=10 lower=1 upper=255 opacity=0 surface=100 interior=50 interpolate");
		run("Make Composite");
		if (scale_bar == true) {
			run("Scale Bar...", "width="+ scale_length +" height=4 font=14 color=White background=None location=[Lower Right] bold overlay");
			}
		print("Saving 3D projection to: " + input + File.separator + "3D_" + file);
		saveAs("Tiff", input  + File.separator + "3D_" + file);
	}
}