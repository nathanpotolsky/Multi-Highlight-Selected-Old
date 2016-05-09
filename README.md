# Highlight Multiple Selected

<!-- [![Build Status](https://travis-ci.org/richrace/highlight-selected.svg?branch=master)](https://travis-ci.org/richrace/highlight-selected) -->

Double click on one or more words to highlight them throughout the open file.

This is a fork of [highlight selected](https://github.com/richrace/highlight-selected).
This is a group project for CSCI 2963 Introduction to Open Source.

Group members:

* [Mukul Surajiwale](https://github.com/mukulio)

* [Ryan Manske](https://github.com/rymanske)

* [Alwin Joy](https://github.com/alwinrobot)

* [Nathan Potolsky](https://github.com/nathanpotolsky)

* [Zhenyu (Victor) Zhu](https://github.com/SLiNv)

Some code and has been taken from Atom's
  [find and replace](https://github.com/atom/find-and-replace) package

Please log any issues and pull requests are more than welcome!

Multiple Colors!

![Gif in action](http://g.recordit.co/W9SeOL3DpQ.gif)

Status Bar!

![Gif in action](https://raw.githubusercontent.com/nathanpotolsky/highlight-selected/master/demo/Status%20bar%20view.gif)

Change the following CSS in your StyleSheet to change the colours to suit your
theme. Either set the light theme check box in settings to be able to toggle
between styles or just overwrite the default box/background.

```scss
atom-text-editor, atom-text-editor::shadow {
  // Box
  .highlights .highlight-selected .region {
    border-color: #ddd;
  }
  // Background
  .highlights .highlight-selected.background .region {
    background-color: rgba(155, 149, 0, 0.6);
  }
  // Light theme box (set in settings)
  .highlights .highlight-selected.light-theme .region {
    border-color: rgba(255, 128, 64, 0.4);
  }
  // Light theme background (set in settings)
  .highlights .highlight-selected.light-theme.background .region {
    background-color: rgba(255, 128, 64, 0.2);
  }
}
```


# Issues and Todo

- Should we highlight symbols?
