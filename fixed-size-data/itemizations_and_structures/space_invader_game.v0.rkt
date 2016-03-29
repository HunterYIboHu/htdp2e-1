;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname designing_with_itemizations_again) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
; Sample Problem: Design a game program using the 2htdp/universe library for
; playing a simple space invader game.
; The palyer is in control of a tank (a small rectangle) that must defend our
; planet (the buttom of the canvas) from a UFO that descends from the top of
; the canvas to the bottom. In order to stop the UFO from landing, the player
; may fire a single missile (a triangle smaller than the tank) by hitting the
; space bar. In response, the missile emerges from the tank.
; If the UFO collides with the missile, the player wins; otherwise the UFO
; lands and the player loses.

; Here are some details concerning the three game objects and their movements.
;
; First, the tank moves a constant speed along the bottom of the canvas
; though the player may use the left arrow key and the right arrow key to
; change directions.
; Second, the UFO descends at a constant velocity but makes small random
; jumps to the left or right.
; Third, once fired the missile ascends along a straight vertical line
; at a constant speed at least twice as fast as the UFO descends.
; Finally, the UFO and the missile collide if their reference points are
; close enough, for whatever you think “close enough” means.