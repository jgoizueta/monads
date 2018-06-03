const xs = [1,2,3];
const ys = [100,200];
const zs = [11,22];

 class List extends Promise {

    then(f) {
      return super.then(v => Promise.all(v.map(x => {
          const v = f(x);
          if (v === undefined) {
              // avoid infinite recursion
              return Promise.resolve(v);
          }
          else {
              return List.resolve([v]);
          }
      })));
    }
 };


// Promise.all([11,22,33].map(x => Promise.resolve(x))).then(r => console.log(r));

// List.resolve(xs).then(x => {
//     List.resolve(ys).then(y => {
//         console.log(x,y);
//     });
// });

List.resolve(xs).then(x => {
    List.resolve(ys).then(y => {
        List.resolve(zs).then(z => {
            console.log(x,y,z);
        });
    });
});

BLOGS = [
    {  id: 'B1', categories: [
      { id: 'C1', posts: [
        { id: 'P1', comments: ['I love cats', 'I love dogs'] },
        { id: 'P2', comments: ['I love mice', 'I love pigs'] }
      ]},
      { id: 'C2', posts: [
        { id: 'P1', comments: ['I hate cats', 'I hate dogs']},
        { id: 'P2', comments: ['I hate mice', 'I hate pigs']}
      ]}
    ]},
    {  id: 'B2', categories: [
      { id: 'C1', posts: [
        { id: 'P1', comments: ['Red is better than blue']}
      ]},
      { id: 'C2', posts: [
        { id: 'P1', comments: ['Blue is better than red']}
      ]}
    ]}
  ];


  List.resolve(BLOGS)
    .then(blog => blog.categories)
    .then(category => {console.log("C",category); return category.posts})
    .then(post => console.log("POST",post));


  words = [];
  List.resolve(BLOGS)
    .then(blog => blog.categories)
    .then(category => category.posts) // the Promise then wrapping interferes and category here is the array of categories, not and individual cat.
    .then(post => post.comments)
    .then(comment => comment.split())
    .then(word => words.push(word));
console.log(words);
