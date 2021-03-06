;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-abbr-reader.ss" "lang")((modname ex203) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
; Develop a data representation for worms with tails. A worm's tail is
; a possibly empty sequence of "connected" segments. Here "connected" means that
; the coordinates of a segment differ grom those of its predecessor in at most
; one direction and, if rendered, the two segments touch. To keep things simple,
; treat all segments -- head and tail segments -- the same.

; Then modify your program form ex201 to accommodate a multi-segment worm.
; Keep things simple: (1) your program may render all worm segments as red disks;
; (2) one way to think of the worm's movement is to add a segment in the direction
; in which it is moving and to delete the last segment; and (3) ignore that the
; worm may run into the wall or into itself.


(require 2htdp/image)
(require 2htdp/universe)


; constants
(define R 5)
(define D (* 2 R))
(define NX 20)
(define NY 20)
(define WIDTH (* NX D))
(define HEIGHT (* NY D))

; visual constants
(define SEG (circle R "solid" "red"))
(define HEAD SEG)
(define MT (empty-scene WIDTH HEIGHT))


; A Direction is one of:
; - "left"
; - "right"
; - "up"
; - "down"


; A Segment is a Posn
; interpretation: an instance of Segment represents one logical position

; A NELos (Non-empty list of segments) is one of:
; - (cons Segment '())
; - (cons Segment Tail)
; interpretation: an instance of NELos represents the location of a worm (logically).
(define l1 (cons (make-posn 5 8) '()))
(define l2 (list (make-posn 10 9)
                 (make-posn 9 9)
                 (make-posn 8 9)))
(define l3 (list (make-posn 15 10)
                 (make-posn 15 9)
                 (make-posn 14 9)))


(define-struct worm [shape d])
; A head is a structure: (make-worm NELos Direction)
; interpretation: (make-head nelos d) represents a worm has the shape shown as nelos,
; and heading to direction d

(define w1 (make-worm l1 "up"))
(define w2 (make-worm l2 "right"))
(define w3 (make-worm l3 "down"))



; Worm -> Image
; adds the image of all segments of w onto the scene

(check-expect (render w1) (place-image SEG (+ R (* 5 D)) (+ R (* 8 D)) MT))

(define (render w)
  (render-segments (worm-shape w)))


; NELos -> Image
; add image of Segment to all the segments in the nelos

(check-expect (render-segments (list (make-posn 5 8)))
              (place-image SEG (+ R (* 5 D)) (+ R (* 8 D)) MT))
(check-expect (render-segments (list (make-posn 10 9)
                                     (make-posn 9 9)
                                     (make-posn 8 9)))
              (place-image SEG (+ R (* 10 D)) (+ R (* 9 D))
                           (place-image SEG (+ R (* 9 D)) (+ R (* 9 D))
                                        (place-image SEG (+ R (* 8 D)) (+ R (* 9 D)) MT))))

(define (render-segments nelos)
  (cond
    [(empty? (rest nelos)) (render-seg MT (first nelos))]
    [else
     (render-seg (render-segments (rest nelos)) (first nelos))]))


; Image Segment -> Image
; form a new image by adding SEG onto im

(check-expect (render-seg MT (make-posn 0 0))
              (place-image SEG
                           R R
                           MT))
(check-expect (render-seg MT (make-posn 5 8))
              (place-image SEG
                           (+ R (* 5 D)) (+ R (* 8 D))
                           MT))

(define (render-seg im seg)
  (place-image SEG
               (+ R (* (posn-x seg) D)) (+ R (* (posn-y seg) D)) 
               im))


; Worm -> Worm
; moves given worm w one its current direction.

(check-expect (tock w1) (make-worm (list (make-posn 5 7)) "up"))
(check-expect (tock w2) (make-worm (list (make-posn 11 9)
                                         (make-posn 10 9)
                                         (make-posn 9 9)) "right"))

(define (tock w)
  (worm-up-shape w (tock-shape w)))


; Worm NELos -> Worm
; Worm' shape field updator
(define (worm-up-shape w segs)
  (make-worm segs
             (worm-d w)))


; Worm -> NELos
; produces the shape of given worm for next time tick.

(check-expect (tock-shape w1) (list (make-posn 5 7)))
(check-expect (tock-shape w2) (list (make-posn 11 9)
                                    (make-posn 10 9)
                                    (make-posn 9 9)))

(define (tock-shape w)
  (cut-the-last
   (add-at-head (worm-shape w)
                (tock-head (first (worm-shape w)) (worm-d w))))) 


; Segment Direction -> Segment
; computes the head position for next time tick,
; current head position and direction

(check-expect (tock-head (make-posn 5 8) "up") (make-posn 5 7))
(check-expect (tock-head (make-posn 10 9) "right") (make-posn 11 9))

(define (tock-head seg d)
  (cond
    [(string=? "left" d) (make-posn (sub1 (posn-x seg)) (posn-y seg))]
    [(string=? "right" d) (make-posn (add1 (posn-x seg)) (posn-y seg))]
    [(string=? "up" d) (make-posn (posn-x seg) (sub1 (posn-y seg)))]
    [(string=? "down" d) (make-posn (posn-x seg) (add1 (posn-y seg)))]))


; NELos Segment -> NELos
; add a new head segment at the head of nelos
(define (add-at-head nelos head)
  (cons head nelos))


; Nelos -> Nelos
; cut the last segment of given nelos which contains at least 2 segments

(check-expect (cut-the-last (list (make-posn 5 7)
                                  (make-posn 5 8)))
              (list (make-posn 5 7)))
(check-expect (cut-the-last (list (make-posn 11 9)
                                  (make-posn 10 9)
                                  (make-posn 9 9)
                                  (make-posn 8 9)))
              (list (make-posn 11 9)
                    (make-posn 10 9)
                    (make-posn 9 9)))

(define (cut-the-last nelos)
  (cond
    [(empty? (rest (rest nelos))) (list (first nelos))]
    [else (cons (first nelos)
                (cut-the-last (rest nelos)))]))



; Worm KeyEvent -> Worm
; controls the worm w with key event ke

(check-expect (control w1 "down") w1)
(check-expect (control w1 "right") (worm-up-d w1 "right"))
(check-expect (control w1 "left") (worm-up-d w1 "left"))
(check-expect (control w2 "right") w2)
(check-expect (control w2 "left") w2)
(check-expect (control w2 "up") (worm-up-d w2 "up"))
(check-expect (control w2 "down") (worm-up-d w2 "down"))

(define (control w ke)
  (cond
    [(and (key=? "left" ke)
          (or (string=? "up" (worm-d w))
              (string=? "down" (worm-d w))))
     (worm-up-d w "left")]
    [(and (key=? "right" ke)
          (or (string=? "up" (worm-d w))
              (string=? "down" (worm-d w))))
     (worm-up-d w "right")]
    [(and (key=? "up" ke)
          (or (string=? "left" (worm-d w))
              (string=? "right" (worm-d w))))
     (worm-up-d w "up")]
    [(and (key=? "down" ke)
          (or (string=? "left" (worm-d w))
              (string=? "right" (worm-d w))))
     (worm-up-d w "down")]
    [else w]))


; Worm Direction -> Worm
; worm's d field updater
(define (worm-up-d w d)
  (make-worm (worm-shape w)
             d))


; Number -> 
; simulates a worm with tail.
(define (main-worm-with-tail r)
  (big-bang w2
            [to-draw render]
            [on-tick tock r]
            [on-key control]))