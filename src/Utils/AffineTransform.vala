/*
* Copyright (c) 2019 Alecaddd (http://alecaddd.com)
*
* This file is part of Akira.
*
* Akira is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* Akira is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Akira.  If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: Giacomo "giacomoalbe" Alberini <giacomoalbe@gmail.com>
*/

using Akira.Lib.Models;
using Akira.Lib.Managers;

public class Akira.Utils.AffineTransform : Object {
    public const int MIN_SIZE = 1;
    private const int MIN_POS = 10;
    private const int BOUNDS_H = 10000;
    private const int BOUNDS_W = 10000;

    public static void move_from_event (
        double x,
        double y,
        double initial_x,
        double initial_y,
        CanvasItem selected_item
    ) {
        Goo.Canvas canvas = selected_item.get_canvas ();

        canvas.convert_to_item_space (selected_item, ref x, ref y);

        double delta_x = Math.round (x - initial_x);
        double delta_y = Math.round (y - initial_y);

        selected_item.translate (delta_x, delta_y);
    }

    public static void scale_from_event (
        double x,
        double y,
        ref double initial_x,
        ref double initial_y,
        double initial_width,
        double initial_height,
        NobManager.Nob selected_nob,
        CanvasItem selected_item
    ) {
        Goo.Canvas canvas = selected_item.get_canvas ();
        canvas.convert_to_item_space (selected_item, ref x, ref y);

        double delta_x = x - initial_x;
        double delta_y = y - initial_y;

        double item_width = selected_item.get_coords ("width");
        double item_height = selected_item.get_coords ("height");

        double new_width = item_width;
        double new_height = item_height;

        double origin_move_delta_x = 0.0;
        double origin_move_delta_y = 0.0;

        switch (selected_nob) {
            case NobManager.Nob.TOP_LEFT:
                new_height = initial_height - delta_y;
                new_width = initial_width - delta_x;

                if (item_height > MIN_SIZE) {
                    origin_move_delta_y = item_height - new_height;
                }

                if (item_width > MIN_SIZE) {
                    origin_move_delta_x = item_width - new_width;
                }
                break;

            case NobManager.Nob.TOP_CENTER:
                new_height = initial_height - delta_y;

                if (item_height > MIN_SIZE) {
                    origin_move_delta_y = item_height - new_height;
                }
                break;

            case NobManager.Nob.TOP_RIGHT:
                new_width = initial_width + delta_x;
                new_height = initial_height - delta_y;

                if (item_height > MIN_SIZE) {
                    origin_move_delta_y = item_height - new_height;
                }
                break;

            case NobManager.Nob.RIGHT_CENTER:
                new_width = initial_width + delta_x;
                break;

            case NobManager.Nob.BOTTOM_RIGHT:
                new_width = initial_width + delta_x;
                new_height = initial_height + delta_y;
                break;

            case NobManager.Nob.BOTTOM_CENTER:
                new_height = initial_height + delta_y;
                break;

            case NobManager.Nob.BOTTOM_LEFT:
                new_height = initial_height + delta_y;
                new_width = initial_width - delta_x;

                if (item_width > MIN_SIZE) {
                    origin_move_delta_x = item_width - new_width;
                }
                break;

            case NobManager.Nob.LEFT_CENTER:
                new_width = initial_width - delta_x;

                if (item_width > MIN_SIZE) {
                    origin_move_delta_x = item_width - new_width;
                }
                break;
        }

        origin_move_delta_x = Math.round (origin_move_delta_x);
        origin_move_delta_y = Math.round (origin_move_delta_y);

        new_width = fix_size (new_width);
        new_height = fix_size (new_height);

        if (new_width == MIN_SIZE) {
            origin_move_delta_x = 0.0;
        }

        if (new_height == MIN_SIZE) {
            origin_move_delta_y = 0.0;
        }

        // Before translating, recover the original "canvas" position of
        // initial_event, in order to convert it to the "new" translated
        // item space after the transformation has been applied.
        canvas.convert_from_item_space (selected_item, ref initial_x, ref initial_y);
        selected_item.translate (origin_move_delta_x, origin_move_delta_y);
        canvas.convert_to_item_space (selected_item, ref initial_x, ref initial_y);

        print ("initial_width %f\n", initial_width);
        print ("initial_height %f\n", initial_height);
        print ("delta x %f\n", delta_x);
        print ("delta y %f\n", delta_y);
        print ("width %f\n", new_width);
        print ("height %f\n", new_height);

        set_size (new_width, new_height, selected_item);
    }

    public static void rotate_from_event (
        double x,
        double y,
        double initial_x,
        double initial_y,
        CanvasItem selected_item
    ) {
        Goo.Canvas canvas = selected_item.get_canvas ();
        canvas.convert_to_item_space (selected_item, ref x, ref y);

        var initial_width = selected_item.get_coords ("width");
        var initial_height = selected_item.get_coords ("height");

        var center_x = initial_width / 2;
        var center_y = initial_height / 2;

        var start_radians = GLib.Math.atan2 (
            center_y - initial_y,
            initial_x - center_x
        );

        var radians = GLib.Math.atan2 (center_y - y, x - center_x);
        radians = start_radians - radians;
        double rotation = radians * (180 / Math.PI);

        initial_x = x;
        initial_y = y;

        canvas.convert_from_item_space (selected_item, ref initial_x, ref initial_y);
        set_rotation (selected_item.rotation + rotation, selected_item);
        canvas.convert_to_item_space (selected_item, ref initial_x, ref initial_y);
    }

    public static void set_position (double? x, double? y, CanvasItem item) {
        var canvas = item.get_canvas ();

        double current_x = item.get_coords ("x");
        double current_y = item.get_coords ("y");

        canvas.convert_from_item_space (item, ref current_x, ref current_y);

        var move_x_amount = 0.0;
        var move_y_amount = 0.0;

        if (x != null) {
            move_x_amount = x - current_x;
        }

        if (y != null) {
            move_y_amount = y - current_y;
        }

        item.translate (move_x_amount, move_y_amount);
    }

    public static void set_size (double? width, double? height, CanvasItem item) {
        if (width != null) {
            item.set ("width", (double) width);
        }

        if (height != null) {
            item.set ("height", (double) height);
        }
    }

    public static void set_rotation (double rotation, CanvasItem item) {
        var center_x = item.get_coords ("width") / 2;
        var center_y = item.get_coords ("height") / 2;

        var actual_rotation = rotation - item.rotation;

        item.rotate (actual_rotation, center_x, center_y);

        item.rotation += actual_rotation;
    }

    /*
    private static double fix_x_position (double x, double width, double delta_x) {
        var min_delta = Math.round (MIN_POS - width);
        var max_delta = Math.round (BOUNDS_H - MIN_POS);

        var new_x = Math.round (x + delta_x);

        if (new_x < min_delta) {
            return 0;
        } else if (new_x > max_delta) {
            return 0;
        } else {
            return delta_x;
        }
    }

    private static double fix_y_position (double y, double height, double delta_y) {
        var min_delta = Math.round (MIN_POS - height);
        var max_delta = Math.round (BOUNDS_H - MIN_POS);

        var new_y = Math.round (y + delta_y);

        if (new_y < min_delta) {
            return 0;
        } else if (new_y > max_delta) {
            return 0;
        } else {
            return delta_y;
        }
    }
    */

    private static double fix_size (double size) {
        var new_size = Math.round (size);
        return new_size > MIN_SIZE ? new_size : MIN_SIZE;
    }
}
