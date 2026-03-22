async function ask(){

let q = document.getElementById("q").value

let res = await fetch("/ask",{
method:"POST",
headers:{
"Content-Type":"application/json"
},
body:JSON.stringify({q})
})

let data = await res.json()

document.getElementById("answer").innerText =
data.choices[0].message.content

}