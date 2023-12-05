import ReactDOMServer from 'react-dom/server';

/**
 * Performs a deep equality comparison between two objects, including nested objects and arrays.
 * @param {Object} obj1 - The first object to compare.
 * @param {Object} obj2 - The second object to compare.
 * @returns {boolean} True if the objects are deeply equal, false otherwise.
 */
const deepEqual = (obj1, obj2) => {
  if (obj1 === obj2) {
    return true;
  }

  if (
    typeof obj1 !== 'object' ||
    typeof obj2 !== 'object' ||
    obj1 === null ||
    obj2 === null
  ) {
    return false;
  }

  const keys1 = Object.keys(obj1);
  const keys2 = Object.keys(obj2);

  if (keys1.length !== keys2.length) {
    return false;
  }

  // eslint-disable-next-line no-unused-vars
  for (const key of keys1) {
    if (!keys2.includes(key) || !deepEqual(obj1[key], obj2[key])) {
      return false;
    }
  }

  return true;
};

const areReactElementsEqual = (element1, element2) => {
  const elementToStr = element =>
    element && ReactDOMServer.renderToStaticMarkup(element);

  const element1Str = elementToStr(element1);
  const element2Str = elementToStr(element2);

  return element1Str === element2Str;
};

/**
 * Recursively copies values from the source hash (`src`) to the destination hash (`dest`).
 *
 * @param {Object} dest - The destination hash to copy values into.
 * @param {Object} src - The source hash from which values are copied.
 * @returns {void} - The function modifies the destination hash in place.
 */
function deepCopy(dest, src) {
  // eslint-disable-next-line no-unused-vars
  for (const key in dest) {
    if (dest.hasOwnProperty(key)) {
      if (src.hasOwnProperty(key)) {
        if (typeof dest[key] === 'object' && typeof src[key] === 'object') {
          deepCopy(dest[key], src[key]);
        } else if (dest[key] !== src[key]) {
          dest[key] = src[key];
        }
      }
    }
  }
}

/**
 * Finds the largest unit from a list that fits the given value.
 *
 * @param {number} value - The value to find the largest fitting unit for.
 * @param {Array<Object>} unitList - An array of unit objects with 'factor' properties.
 * @returns {Object} The largest unit object that fits the value.
 */
const findLargestFittingUnit = (value, unitList) => {
  for (let i = unitList.length - 1; i >= 0; i--) {
    if (value >= unitList[i].factor) return unitList[i];
  }
  return unitList[0];
};

export { deepEqual, deepCopy, findLargestFittingUnit, areReactElementsEqual };
