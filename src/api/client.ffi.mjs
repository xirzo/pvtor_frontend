
export async function fetchWithCredentials(url, method, headers, body) {
    try {
        const opts = {
            method: method,
            headers: new Headers(headers),
            credentials: "include",
        };
        if (body) {
            opts.body = body;
        }

        const response = await fetch(url, opts);
        const text = await response.text();
        const headersList = [];
        response.headers.forEach((v, k) => headersList.push([k, v]));

        return {
            status: response.status,
            body: text,
            headers: headersList,
        };
    } catch (error) {
        return { error: error.toString() };
    }
}
