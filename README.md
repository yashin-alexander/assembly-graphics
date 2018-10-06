# Assembly Graphics

Small raster graphics library for black & white mode on CGA video adapter.

### API Reference

- `draw_white_point` procedure
```
Parameters:
    Numeric representation of pixel address in ax register.
```

- `transform_coordinates` procedure

```
Parameters:
    'x' point coordinate in dx register.
    'y' point coordinate in ax register.
Return value:
    Numeric representation of pixel address in ax register.
```

- `draw_line` procedure

```
Draws a line from point A to point B using Bresenham's line algorithm.
Parameters:
    'x' and 'y' coordinates of A point in a_x and a_y.
    'x' and 'y' coordinates of B point in b_x and b_y.
```

- `draw_circle` procedure

```
Draws a circle with center in point A and with specifie radius using Starodubtsev algorithm.
Parameters:
    'x' and 'y' coordinates of circle center in a_x and a_y.
    circle radius in 'radius'.

```

- `fill_area` procedure

```
Fills area in which the specified point is placed using boundary fill algorithm.
Parameters:
    'x' and 'y' coordinates of the point in a_x and a_y.
```

### Requirements
 - Dosbox
 - `TASM.EXE` and `TLINK.exe` in the `tools` directory. 

### Run example
In `dosbox`:
```
    mount c \path\to\assembly-graphics\repository
    c:
    MAKE.bat
    PAINTER.EXE
```
You can add this lines to your `.dosbox.conf` to make dosbox execute it automatically on each startup.

![Alt Text](flying_circle.gif)

A flying circle will appear!