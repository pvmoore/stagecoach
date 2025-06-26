module stagecoach.utils.container_utils;

import stagecoach.all;

import std.stdio  : writeln;
import std.traits : isSomeString, isSomeChar;

// ------------------------------------------------------------- Array functions

T first(T)(T[] array) { return array.length > 0 ? array[0] : T.init; }
T last(T)(T[] array) { return array.length > 0 ? array[$-1] : T.init; }

bool contains(string s, string substr) {
    import std.string : indexOf;
    if(s is null || substr is null) return false;
    return s.indexOf(substr) != -1;
}

bool startsWith(string s, string prefix) {
    if(s is null || prefix is null) return false;
    if(s.length < prefix.length) return false;
    return s[0..prefix.length] == prefix;
}

bool endsWith(string s, string suffix) {
    if(s is null || suffix is null) return false;
    if(s.length < suffix.length) return false;
    return s[$-suffix.length..$] == suffix;
}

int indexOf(T)(T[] array, T value) if(!isSomeChar!T) {
    foreach(i, v; array) if(v==value) return cast(int)i;
    return -1;
}

/** 
 * Remove the first instance of 'value' in the array and return true if found, false otherwise
 */
bool remove(T)(ref T[] array, T value) {
	foreach(i, v; array) {
        if(v == value) {
            array.removeAt(i);
            return true;
        }
    }
    return false;
}

/** auto v = array.removeAt(i) */
T removeAt(T)(ref T[] array, ulong index) {
	assert(index < array.length);

	T element = array[index];

	import core.stdc.string : memmove;

	T* dest    = array.ptr + index;
	T* src     = array.ptr + index + 1;
	ulong size = (array.length - index) - 1;

	memmove(dest, src, size * T.sizeof);

	array.length = array.length - 1;
	return element;
}

void insertAt(T)(ref T[] array, ulong index, T value) {
    import std.array  : insertInPlace;
    insertInPlace(array, index, value);
}

void swap(T)(ref T[] array, ulong index1, ulong index2) {
    T temp = array[index1];
    array[index1] = array[index2];
    array[index2] = temp;
}

T[] unique(T)(T[] a) {
    import std.algorithm : uniq, sort;
    return a.sort().uniq.array;
}

// ------------------------------------------------------------- Range functions

/**
 * Return the front of the range or the default value if the range is empty.
 * 
 * auto value = [1,2,3].filter!(it=>it>2).frontOrElse(0);
 */
T frontOrElse(T,Range)(Range r, T defaultValue) {
    import std.range;
    return cast(T)(r.empty ? defaultValue : r.front);
}

// ------------------------------------------------------------- Map functions

bool containsKey(K,V)(V[K] map, K key) {
    return (key in map) !is null;
}
