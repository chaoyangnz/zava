const doc = Array.from(document.querySelectorAll('.section-execution')).map(instruction => ({
    name: instruction.getAttribute('title'),
    link: instruction.querySelector('a').getAttribute('name'),
    sections: Array.from(instruction.querySelectorAll('.section')).map(section => ({
        title: section.getAttribute('title'),
        content: Array.from(section.querySelectorAll('p')).map(p => p.textContent.trim())
    })
    )
})        
)

function comment(inst) {
    let text = `/// https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html#${inst.link}\n`
    inst.sections.forEach(section => {
        text += `/// ${section.title}\n`
        section.content.forEach(p => {
            text += `///    ${p.replaceAll(/[\n\r]\s+/g, '\n///    ')}\n`
        })
    })
    const name = inst.name.replace(/<\w*>/, 0)
    const fn = `fn ${name}(ctx: Context) void {`
    text += fn
    f = f.replace(fn, text)
    return text
}

doc.forEach(inst => comment(inst))