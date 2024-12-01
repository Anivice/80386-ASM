# Chapter 4: Loading a Program

The boot sector has a maximum size of 512 bytes, making it extremely limited in capacity.
Often, it serves as a loader to load more complex programs into memory. These programs are
not necessarily operating system kernels but can include sophisticated tools like advanced
bootloaders.

Now, this chapter is one of those that is long and tedious, and potentially confusing.
I'll try my best to negate all these factors, but if they still persist, I apologize in advance.

In this chapter, we have the following goal to accomplish:
1. Access hardware beyond processor scope.
2. Program loading process that demonstrates the relocation of segmentations.

The Master Boot Record (MBR) we attempt to write this time is a loader that loads the program at the next
sector, and 

---

[Chapter 5](./5_other_hardware_control.md)

[Back to the Main Page](../README.md)

