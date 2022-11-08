let ensureArray: array<'a> => array<'a> = %raw(`
  function(maybeArray) {
    if (Array.isArray(maybeArray)) {
      return maybeArray;
    }

    return [maybeArray];
  }
`)
