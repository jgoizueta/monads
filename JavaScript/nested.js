
Promise.prototype.nested = function(...functions) {
    this._nested_recursive(this, [], functions);
};
Promise.prototype._nested_recursive = function(current, results, functions) {
    let func = functions[0]
    functions = functions.slice(1, functions.length)
    if (func) {
      let result;
      current.then(v => {
        let next_results = results.concat([v]);
        if (func.length === 1) {
          result = func(v)
        }
        else {
          result = func(...next_results);
        }
        if (functions.length > 0) {
            let next_one = result;
            if (typeof(next_one.then) !== 'function') {
                next_one = Promise.resolve(result);
            }
            this._nested_recursive(next_one, next_results, functions)
        }
        return result; // next_one
      });
    }
    return results;
};

const promise = Promise.resolve(100);
const step1 = (r1) => r1*2;
const step2 = (r1, r2) => r2/r1;
const step3 = (r1, r2, r3) => console.log('r1',r1,'r2',r2,'r3',r3);


promise.nested(
    r1 => step1(r1),
    (r1, r2) => step2(r1, r2),
    (r1, r2, r3) => step3(r1, r2, r3)
);

promise.then(r1 => {
    Promise.resolve(step1(r1)).then(r2 => {
        Promise.resolve(step2(r1, r2)).then(r3 => {
            step3(r1, r2, r3);
        });
    });
});

const pstep1 = (r1) => Promise.resolve(r1*2);
const pstep2 = (r1, r2) => Promise.resolve(r2/r1);
const pstep3 = (r1, r2, r3) => console.log('r1',r1,'r2',r2,'r3',r3);

promise.nested(
    r1 => pstep1(r1),
    (r1, r2) => pstep2(r1, r2),
    (r1, r2, r3) => pstep3(r1, r2, r3)
);

promise.then(r1 => {
    pstep1(r1).then(r2 => {
        pstep2(r1, r2).then(r3 => {
            pstep3(r1, r2, r3);
        });
    });
});

// a step either uses all previous arguments or just the result from the last one

const xstep1 = (r1) => Promise.resolve(r1*2);
const xstep2 = (r2) => Promise.resolve(r2+40);
const xstep3 = (r1, r2, r3) => console.log('r1',r1,'r2',r2,'r3',r3);

promise.nested(
    r1 => xstep1(r1),
    r2 => xstep2(r2),
    (r1, r2, r3) => xstep3(r1, r2, r3)
);

promise.then(r1 => {
    xstep1(r1).then(r2 => {
        xstep2(r2).then(r3 => {
            xstep3(r1, r2, r3);
        });
    });
});
