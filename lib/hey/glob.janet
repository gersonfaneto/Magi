# lib/hey/glob.janet
#
# Shell-style glob patterns, compiled to PEGs.

(use ./lib)

(def peg
  (peg/compile
   ~{:main (* (any :rule) -1)
     :rule (* (+ (* "***" (error (constant "invalid glob pattern")))
                 (* "**" (error (constant "** not supported")))
                 :1star
                 :qmark
                 :lit))
     :qmark (* "?" (constant 1))
     :1star (+ (* "*" -1 (constant (any 1)))
               (cmt (* "*" :lit) ,(fn [lit] ~(* (any (sequence (not ,lit) 1)) ,lit))))
     :lit (capture (some (* (not (set "*?")) 1)))}))

(defn to-peg [glob]
  ~{:main (* ,;(peg/match peg glob) -1)})

(defn match* [glob to-match]
  (truthy? (peg/match (to-peg glob) to-match)))

(defn- match-form
  ``Build the test form that matches GLOB, a string literal, against the form
  TO-MATCH. The PEG is compiled here, at expansion time.``
  [glob to-match]
  (unless (string? glob)
    (error "use glob/match* when glob is not a string literal"))
  ~(,truthy? (,peg/match ,(peg/compile (to-peg glob)) ,to-match)))

(defmacro match [glob to-match]
  (match-form glob to-match))

(defmacro case [value & clauses]
  (with-syms [$var]
    ~(let [,$var ,value]
       (cond ,;(case-body (fn [pred] (match-form pred $var)) clauses)))))
