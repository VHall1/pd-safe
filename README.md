
# pd-safe

**How to use**

You can create as many locks as you want. It will be generated based on how many random numbers are provided to the **createSafe** function;
Also, you shall only provide numbers **between 0 and 99**, otherwise it will be impossible to **finish the minigame properly!**
`````lua
local res = exports["pd-safe"]:createSafe({math.random(0,99)})
`````
*The final result is returned as soon as the minigame is finished*

*This code was originally developed in C#. You can access the original repository by clicking on the [following link](https://github.com/TimothyDexter/FiveM-SafeCrackingMiniGame)*

[Sample Video](https://www.youtube.com/watch?v=bmsPNMACUsY)
