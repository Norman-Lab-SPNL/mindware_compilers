# mindware_compilers
R files for compiling HRV, PEP, and EDA from Mindware.

See the instructions file (markdown or HTML) for... instructions.
  
HRV Compiler:
For each segment, need to make sure they were breathing within the respiratory band
So for each segment check that the corresponding respiration frequency value is between 0,12 and 0.4 Hz
Value in mindware output is in cycles per minute so need to transform to Hz
If respiration rate for the segment is not within the range, drop the segment
Also need to return a warning or something saying how many segments were dropped (and which ones maybe)

  