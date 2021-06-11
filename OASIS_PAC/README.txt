Edits from original Tustison OASIS template:

1. Cropped to reduce empty space around template head (and hence reduce file sizes)

2. Removed junk from background (low intensity fringe surrounding head)

3. Created custom reg mask by dilating head mask, cropped tighter in face region
   to try to alleviate troubles registering images with faces

4. Edited the origin of the template to be at the anterior commissure

5. Re-masked template with brain mask to make brain image that does not have zeros in any 
   of the ventricles.
