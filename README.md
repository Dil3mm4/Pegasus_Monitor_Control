<div align="center">
<a href="https://github.com/waydabber/BetterDisplay/releases">
  <img src="https://github.com/user-attachments/assets/79774821-669c-4bf9-b986-7a7cff02fe3e" width="280" alt="Pegasus Monitor Control" align="center"/></a>
<h1>Pegasus Monitor Control</h1>
</div>

### Control you PG27UCDM from your Apple Silicon Mac device.

> [!Warning]  
> This app was made on a caffeine rush, with no knowledge of Swift nor of the DDC protocol.
>
> I have almost 0 interest in maintaining it on the long run, so you get what you see.
>
> Feel free to fork, pull request, to improve this software, I might learn a thing or two.
>
> Feel also free to open issues, with no guarantees I will address them.

## Features
This app mimicks 99% of what the [ASUS Display Widget Center](https://www.asus.com/content/monitor-software-osd-displaywidgetcenter/) does on Windows.

With no AI, more caffeine, a sprinkle of quirks, no internal knowledge of the VCP codes ASUS has and no team to code it.

## Known quirks

- AURA lights aren't controllable from the app itself (can be accessed by via OSD via key combos)
- PIP source misses DisplayPort (I have no idea what ASUS has done with this VCP code, it's odd)
- Swapping HDR presets might black out the screen (at least it does over USB-C/DPalt), nothing an input source swap from OSD can't fix
- Adjustable HDR works only on HDR Console presets (both Dolby and "standard")

## Screenshots 
<details>
  <summary>Click me</summary>
  
![Screenshot 2025-05-12 alle 06 12 22](https://github.com/user-attachments/assets/e2b746cd-3cfb-417b-991d-9b077157a6bf)
![Screenshot 2025-05-12 alle 06 12 23](https://github.com/user-attachments/assets/2ab68301-6cd6-4986-9dbf-18b8e6829281)
![Screenshot 2025-05-12 alle 06 11 34](https://github.com/user-attachments/assets/cfc6c7dd-ac82-4c74-95d6-18d59aa49348)
![Screenshot 2025-05-12 alle 06 12 34](https://github.com/user-attachments/assets/1fd517b9-0cbe-4cf3-9a53-ff5f59da12a6)
![Screenshot 2025-05-12 alle 06 12 38](https://github.com/user-attachments/assets/27efe88b-f6e1-4673-b1df-2a3da9e84d0e)
![Screenshot 2025-05-12 alle 06 12 41](https://github.com/user-attachments/assets/7c63fe7c-6acb-474e-932a-04d378f34a47)
![Screenshot 2025-05-12 alle 06 12 47](https://github.com/user-attachments/assets/cce11a12-d8be-495a-88e3-8f01726ae288)
![Screenshot 2025-05-12 alle 06 12 52](https://github.com/user-attachments/assets/93308879-908c-4a07-9141-ad2b3c183099)
![Screenshot 2025-05-12 alle 06 12 56](https://github.com/user-attachments/assets/b85620ad-5224-4822-8c7a-47b326ac1c0d)
![Screenshot 2025-05-12 alle 06 13 00](https://github.com/user-attachments/assets/cd7e9846-0a41-432d-86ed-ee43abaf7220)
![Screenshot 2025-05-12 alle 06 13 25](https://github.com/user-attachments/assets/72168c59-6a8d-43ed-93b3-9f406459f8d0)

</details>

## License
The entirety of this repository except where the author in the header of the file isn't "Francesco Manzo", is under GPLv3 license.

## For the daring
I will upload a sheet with all the findings I have about this monitor.


Maybe someone more knowledgeable than me, might figure out something that I didn't.


> [!Note]
> For developers, don't hate my formatting, I don't know Swift indent rules nor general formatting etiquette, what you see it's gentle concession of XCode's formatting tools.

Thanks to @waydabber and @alin23
