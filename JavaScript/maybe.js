
async function ops(v) {
  return v.then(v => 2*v).then(v => v+100);
}

async function ops2(v) {
  return v.then(v => 2*v).then(() => undefined).then(v => v+100);
}

ops(Promise.resolve(11)).then(v => console.log("P 11", v));
ops(Promise.resolve(undefined)).then(v => console.log("P u", v));
ops2(Promise.resolve(11)).then(v => console.log("P2 11", v));

// (Promise rejection can arguably be interpreted as a Maybe mechanism)
class Maybe extends Promise {

  static nothing() {
    return Maybe.resolve(undefined);
  }

  then(f) {
    return super.then(v => {
      if (v === undefined) {
        // return this or any Maybe monad leads to infinite recursion here
        // we could also return Maybe.reject('nothing')
        return v;
      }
      return f(v); // Maybe.resolve(f(v));
    });
  }
};

ops(Maybe.resolve(11)).then(v => console.log("M 11", v));
ops(Maybe.nothing()).then(v => console.log("M u", v));
ops2(Maybe.resolve(11)).then(v => console.log("M2 11", v));
