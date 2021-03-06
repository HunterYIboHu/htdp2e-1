;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname ex103) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
; Design the functions si-move.v2, si-game-over.v2?, and si-control.v2 to
; comlplete the game for this second data definition.

(require 2htdp/image)
(require 2htdp/universe)

; physical constants
(define WIDTH 200)
(define HEIGHT 200)

(define HALF-WIDTH (/ WIDTH 2))

(define TANK-WIDTH 80)
(define TANK-HEIGHT 20)

(define MISSILE-SIZE 10)

(define TANK-SPEED-X 3)
(define UFO-SPEED-Y 3)
(define MISSILE-SPEED-Y -7)

(define DELTA-X 10)

; visual constants
(define MT (empty-scene WIDTH HEIGHT))
(define UFO
  (overlay (circle 5 "solid" "green")
           (rectangle 20 2 "solid" "green")))
(define TANK
  (rectangle TANK-WIDTH TANK-HEIGHT "solid" "blue"))
(define MISSILE
  (triangle MISSILE-SIZE "outline" "red"))

(define TANK-Y (- HEIGHT (/ TANK-HEIGHT 2)))
(define UNFIRED-MISSILE-Y (- HEIGHT (+ TANK-HEIGHT (/ (image-height MISSILE) 2))))

(define HALF-UFO-HEIGHT (/ (image-height UFO) 2))
(define HALF-UFO-WIDTH (/ (image-width UFO) 2))
(define HALF-MISSILE-HEIGHT (/ (image-height MISSILE) 2))
(define HALF-MISSILE-WIDTH (/ (image-width MISSILE) 2))

;; Data Definition

; A UFO is Posn.
; interpretation: (make-posn x y) is the UFO's current location


(define-struct tank [loc vel])
; A Tank is a structure: (make-tank Number Number)
; interpretation: (make-tank x dx) means the tank is at position (x, TANK-Y)
; and it moves dx pixels per clock tick


; A MissileOrNot is one of:
; - #false
; - Posn
; interpretation: #false means the missile hasn't been fired yet;
; Posn says the missile has been fired and is at the specified location.


(define-struct sigs [ufo tank missile])
; SIGS.v2 (short for version 2)
; is a structure: (make-sigs UFO Tank MissileOrNot)
; interpretation: represents the state of the space invader game

(define ex1 (make-sigs (make-posn 50 10) (make-tank 28 -3) #false))

(define ex2 (make-sigs (make-posn 50 10)
                       (make-tank 28 -3)
                       (make-posn 28 UNFIRED-MISSILE-Y)))

(define ex3 (make-sigs (make-posn 20 100)
                       (make-tank 100 3)
                       (make-posn 22 103)))

(define ex4 (make-sigs (make-posn 20 100)
                       (make-tank 100 3)
                       (make-posn 32
                                  (- HEIGHT
                                     TANK-HEIGHT
                                     10))))


; SIGS.v2 -> Image
; renders the given game state and added it to MT

(check-expect (si-render.v2 ex1)
              (tank-render (make-tank 28 -3)
                           (ufo-render (make-posn 50 10) MT)))

(check-expect (si-render.v2 ex4)
              (tank-render (make-tank 100 3)
                           (ufo-render (make-posn 20 100)
                                       (missile-render.v2
                                        (make-posn 32
                                                   (- HEIGHT
                                                      TANK-HEIGHT
                                                      10))
                                        MT))))

(define (si-render.v2 s)
  (tank-render (sigs-tank s)
               (ufo-render (sigs-ufo s)
                           (missile-render.v2 (sigs-missile s)
                                              MT))))


; Tank Image -> Image
; adds t to the given image im

(check-expect (tank-render (make-tank 40 -3) MT)
              (place-image TANK
                           40 TANK-Y
                           MT))

(define (tank-render t im)
  (place-image TANK
               (tank-loc t) TANK-Y
               im))


; UFO Image -> Image
; add u to the given image im

(check-expect (ufo-render (make-posn 30 50) MT)
              (place-image UFO
                           30 50
                           MT))

(define (ufo-render u im)
  (place-image UFO
               (posn-x u) (posn-y u)
               im))


; MissileOrNot Image -> Image
; adds the missile image to sc for m

(define scene (tank-render (make-tank 40 -3)
                           (ufo-render (make-posn 20 10) MT)))

(check-expect (missile-render.v2 false scene) scene)

(check-expect (missile-render.v2 (make-posn 32 (- HEIGHT
                                                  TANK-HEIGHT
                                                  10))
                                 scene)
              (place-image MISSILE
                           32 (- HEIGHT TANK-HEIGHT 10)
                           scene))

(define (missile-render.v2 m sc)
  (cond
    [(false? m) sc]
    [(posn? m) (place-image MISSILE
                            (posn-x m) (posn-y m)
                            sc)]))


; SIGS.v2 -> Boolean
; determines whether current state s is aiming

(check-expect (aim? ex1) #t)
(check-expect (aim? ex3) #f)

(define (aim? s)
  (false? (sigs-missile s)))


; SIGS.v2 -> Boolean
; determines whether current state s is fired

(check-expect (fired? ex1) #f)
(check-expect (fired? ex3) #t)

(define (fired? s)
  (posn? (sigs-missile s)))


; SIGS.v2 -> SIGS.v2
; calculates the state after one clock tick, with the given state s
(define (si-move.v2 s)
  (si-move-proper.v2 s (create-random-number s)))


; SIGS.v2 Number -> SIGS.v2
; determines the state of next clock tick with the given dx for UFO

(check-expect (si-move-proper.v2 ex1 6)
              (make-sigs (make-posn (+ 50 6)
                                    (+ 10 UFO-SPEED-Y))
                         (make-tank (+ 28 -3) -3)
                         #f))
(check-expect (si-move-proper.v2 ex2 -5)
              (make-sigs (make-posn (+ 50 -5)
                                    (+ 10 UFO-SPEED-Y))
                         (make-tank (+ 28 -3) -3)
                         (make-posn 28
                                    (+ UNFIRED-MISSILE-Y MISSILE-SPEED-Y))))

(define (si-move-proper.v2 s dx)
  (cond
    [(aim? s)
     (make-sigs (make-posn (+ (posn-x (sigs-ufo s)) dx)
                           (+ (posn-y (sigs-ufo s)) UFO-SPEED-Y))
                (make-tank (+ (tank-loc (sigs-tank s))
                              (tank-vel (sigs-tank s)))
                           (tank-vel (sigs-tank s)))
                #f)]
    [(fired? s)
     (make-sigs (make-posn (+ (posn-x (sigs-ufo s)) dx)
                           (+ (posn-y (sigs-ufo s)) UFO-SPEED-Y))
                (make-tank (+ (tank-loc (sigs-tank s))
                              (tank-vel (sigs-tank s)))
                           (tank-vel (sigs-tank s)))
                (make-posn (posn-x (sigs-missile s))
                           (+ (posn-y (sigs-missile s)) MISSILE-SPEED-Y)))]))


; SIGS -> Number
; create a random number in case a UFO should perform a horizontal jump 

(check-random (create-random-number ex1) (- (random DELTA-X) (/ DELTA-X 2)))

(define (create-random-number w)
  (- (random DELTA-X) (/ DELTA-X 2)))


; SIGS.v2 -> Boolean
; determines whether the game is over

(check-expect (si-game-over.v2? ex1) #f)
(check-expect (si-game-over.v2? ex3) #t)

(define (si-game-over.v2? s)
  (or (hit-ground? (sigs-ufo s))
      (collide? (sigs-ufo s)
                (sigs-missile s))))


; SIGS.v2 -> Image
; render the state s when the game is over
(check-expect (si-render-final.v2 ex3)
              (place-image (text "You Win!" 16 "red")
                           (/ WIDTH 2) (/ HEIGHT 2)
                           (si-render.v2 ex3)))
(check-expect (si-render-final.v2 (make-sigs (make-posn 50 HEIGHT)
                                             (make-tank 100 3)
                                             (make-posn 70 70)))
              (place-image (text "You Lose!" 16 "black")
                           (/ WIDTH 2) (/ HEIGHT 2)
                           (si-render.v2 (make-sigs (make-posn 50 HEIGHT)
                                                    (make-tank 100 3)
                                                    (make-posn 70 70)))))

(define (si-render-final.v2 s)
  (cond
    [(hit-ground? (sigs-ufo s))
     (render-result s "You Lose!" "black")]
    [(collide? (sigs-ufo s) (sigs-missile s))
     (render-result s "You Win!" "red")]))


; SIGS.v2 String String -> Image
; render given state s with colored txt on the canvas.
(define (render-result s txt color)
  (place-image (text txt 16 color)
               (/ WIDTH 2) (/ HEIGHT 2)
               (si-render.v2 s)))

; UFO -> Boolean
; determines whether the u hits ground

(check-expect (hit-ground? (make-posn 100 HEIGHT)) #t)
(check-expect (hit-ground? (make-posn 100 (- HEIGHT HALF-UFO-HEIGHT 2))) #f)
(check-expect (hit-ground? (make-posn 100 (- HEIGHT HALF-UFO-HEIGHT))) #t)


(define (hit-ground? u)
  (>= (+ (posn-y u) HALF-UFO-HEIGHT) HEIGHT))


; UFO Missile -> Boolean
; determins whether the missile m has hit the UFO u

(check-expect (collide? (make-posn 33 40)
                        #f)
              #f)
(check-expect (collide? (make-posn 20 100)
                        (make-posn 22 103))
              #t)
(check-expect (collide? (make-posn 50 110)
                        (make-posn 44 130))
              #f)

(define (collide? u m)
  (and
   (posn? m)
   (<= (abs (- (posn-x u) (posn-x m)))
       (+ HALF-UFO-WIDTH HALF-MISSILE-WIDTH))
   (<= (abs (- (posn-y u) (posn-y m)))
       (+ HALF-UFO-HEIGHT HALF-MISSILE-HEIGHT))))



; SIGS.v2 KeyEvent -> SIGS.v2
; key event handler

(check-expect (si-control.v2 ex1 " ") ex2)
(check-expect (si-control.v2 ex2 " ") ex2)

(check-expect (si-control.v2 ex1 "left") ex1)
(check-expect (si-control.v2 ex1 "right")
              (make-sigs (make-posn 50 10) (make-tank 28 3) #f))

(check-expect (si-control.v2 ex2 "left") ex2)
(check-expect (si-control.v2 ex2 "right")
              (make-sigs (make-posn 50 10)
                         (make-tank 28 3)
                         (make-posn 28 UNFIRED-MISSILE-Y)))

(define (si-control.v2 s ke)
  (cond
    [(and (string=? " " ke) (aim? s))
     (make-sigs (sigs-ufo s)
                (sigs-tank s)
                (make-posn (tank-loc (sigs-tank s))
                           UNFIRED-MISSILE-Y))]
    [(string=? "right" ke)
     (make-sigs (sigs-ufo s)
                (make-tank (tank-loc (sigs-tank s))
                           (abs (tank-vel (sigs-tank s))))
                (sigs-missile s))]
    [(string=? "left" ke)
     (make-sigs (sigs-ufo s)
                (make-tank (tank-loc (sigs-tank s))
                           (- (abs (tank-vel (sigs-tank s)))))
                (sigs-missile s))]
    [else s]))


; SIGS.v2 -> SIGS.v2
; space invader game simulator
(define (si-main.v2 s)
  (big-bang s
            [to-draw si-render.v2]
            [on-key si-control.v2]
            [stop-when si-game-over.v2? si-render-final.v2]
            [on-tick si-move.v2 0.2]))


; a sample simulation
; (si-main.v2 ex1)