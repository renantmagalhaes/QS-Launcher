.pragma library

function evaluate(query) {
    if (!query) return null;
    let trimmed = query.trim();
    if (trimmed.length < 3) return null;
    
    // Whitelist numbers and basic operators: + - * / ( ) . ^ %
    // This regex matches simple arithmetic expressions.
    const mathRegex = /^[0-9+\-*/().\s^%]+$/;
    if (!mathRegex.test(trimmed)) return null;
    
    // Ensure there's at least one operator to distinguish from plain numbers
    if (!/[+\-*/^%]/.test(trimmed)) return null;

    try {
        // Replace ^ with ** for Javascript power operator
        let expression = trimmed.replace(/\^/g, "**");
        
        // Use a Function constructor as it's often slightly safer/isolated than eval
        // Though in QML both are similar.
        let result = new Function("return " + expression)();
        
        if (typeof result === "number" && isFinite(result)) {
            let formatted;
            if (result % 1 !== 0) {
                // Round to 8 places then strip trailing zeros
                formatted = result.toFixed(8).replace(/\.?0+$/, "");
            } else {
                formatted = result.toString();
            }
            console.log("[Calculator] " + trimmed + " = " + formatted);
            return formatted;
        }
    } catch (e) {
        // Invalid expression or calculation error
    }
    return null;
}
