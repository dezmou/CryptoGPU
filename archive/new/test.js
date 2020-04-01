const titi = {
    ...(() => {
        const key = 'test'
        return {
            key, value : new RegExp(key)
        }
    })()
}

console.log(titi);