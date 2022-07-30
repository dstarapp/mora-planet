/*
 * A mutable queue with pushFront and pushBack, but only popFront.
 *
 */
import Iter "mo:base/Iter";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";

import Matchers "mo:matchers/Matchers";
import T "mo:matchers/Testable";
import Suite "mo:matchers/Suite";

module DQueue {
  public type List<T> = {
    item: T;
    var next: ?List<T>;
    var prev: ?List<T>;
  };

  public type DQueue<T> = {
    var size: Nat64;
    var first: ?List<T>;
    var last: ?List<T>;
  };

  public func empty<T>() : DQueue<T> {
    { var size = 0; var first = null; var last = null; }
  };

  public func pushBack<T>(q: DQueue<T>, item: T) : DQueue<T> {
    let list : List<T> = { item = item; var next = null; var prev = null; };
    switch (q.first, q.last) {
      case (?first, ?last) {
        list.prev := ?last;
        last.next := ?list;
        q.last := last.next;
      };
      case (_, _) {
        q.first := ?list;
        q.last := q.first;
      }
    };
    q.size := q.size + 1;
    q
  };

  public func pushFront<T>(item: T, q: DQueue<T>) : DQueue<T> {
    let list : List<T> = { item = item; var next = null; var prev = null; };
    switch (q.first, q.last) {
      case (?first, ?last) {
        first.prev := ?list;
        list.next := ?first;
        q.first := ?list;
      };
      case (_, _) {
        q.first := ?list;
        q.last := q.first;
      }
    };
    q.size := q.size + 1;
    q
  };

  public func popFront<T>(q: DQueue<T>) : ?T {
    switch (q.first, q.last) {
      case (?first, ?last) {
        q.size := q.size - 1;
        let item = first.item;
        if (q.size == 0) {
          q.first := null;
          q.last := null;
        } else {
          q.first := first.next;
        };
        ?item
      };
      case (_, _) null;
    }
  };

  public func rotate<T>(q: DQueue<T>) : DQueue<T> {
    switch (q.first, q.last) {
      case (?first, ?last) {
        if (q.size > 1) {
          q.first := first.next;
          first.next := null;
          last.next := ?first;
          q.last := last.next;
        }
      };
      case (_, _) ();
    };
    q
  };

  public func remove<T>(q: DQueue<T>, eq: T -> Bool) : DQueue<T> {
    ignore removeOne(q, eq);
    q
  };

  public func removeOne<T>(q: DQueue<T>, eq: T -> Bool) : ?T {
    switch (q.first, q.last) {
      case (?first, ?last) {
        if (eq(first.item)) {
          q.first := first.next;
          switch(q.first) {
            case(?qfirst){
              qfirst.prev := null;
            };
            case(_){
              q.last := null;
            }
          };
          q.size := q.size - 1;
          ?first.item;
        } else {
          var prev = first;
          label L loop {
            switch (prev.next) {
              case null { break L };
              case (?next) {
                if (eq(next.item)) {
                  prev.next := next.next;
                  switch(prev.next) {
                    case(?pnext) {
                      pnext.prev := ?prev;
                    };
                    case(_){
                      q.last := ?prev;
                    }
                  };
                  q.size := q.size - 1;
                  return ?next.item;
                };
                prev := next;
              }
            }
          };
          null
        }
      };
      case _ { null };
    }
  };

  public func first<T>(q: DQueue<T>) : ?T {
    Option.map(q.first, func (x: List<T>) : T { x.item })
  };

  public func last<T>(q: DQueue<T>) : ?T {
    Option.map(q.last, func (x: List<T>) : T { x.item })
  };

  public func make<T>(item: T) : DQueue<T> {
    let q = empty<T>();
    pushBack<T>(q, item)
  };

  public func size<T>(q: DQueue<T>) : Nat {
    Nat64.toNat(q.size)
  };

  public func toIter<T>(q: DQueue<T>) : Iter.Iter<T> {
    var cursor = q.first;
    func next() : ?T {
      switch (cursor) {
        case null null;
        case (?list) {
          let item = list.item;
          cursor := list.next;
          ?item
        }
      }
    };
    { next = next }
  };

  public func toReverseIter<T>(q: DQueue<T>) : Iter.Iter<T> {
    var cursor = q.last;
    func next() : ?T {
      switch (cursor) {
        case null null;
        case (?list) {
          let item = list.item;
          cursor := list.prev;
          ?item
        }
      }
    };
    { next = next }
  };

  public func find<T>(q: DQueue<T>, f: T -> Bool) : ?T {
    for (item in toIter(q)) {
      if (f(item)) { return ?item }
    };
    null
  };

  public func fold<T, V>(q: DQueue<T>, init: V, acc: (V, T) -> V) : V {
    var sum = init;
    for (item in toIter(q)) {
      sum := acc(sum, item);
    };
    sum
  };

  public func fromIter<T>(iter: Iter.Iter<T>) : DQueue<T> {
    let q = empty<T>();
    for (item in iter) {
      ignore pushBack(q, item);
    };
    q
  };

  public func fromArray<T>(arr: [T]) : DQueue<T> {
    fromIter(Iter.fromArray(arr))
  };

  public func toArray<T>(q: DQueue<T>) : [T] {
    Iter.toArray<T>(toIter(q))
  };

  public func map<A, B>(inp: DQueue<A>, f: A -> B) : DQueue<B> {
    let out = DQueue.empty<B>();
    for (x in toIter(inp)) {
      ignore pushBack(out, f(x));
    };
    out
  };
}

