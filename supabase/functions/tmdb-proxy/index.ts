import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0"

// Types
interface MovieCache {
  id: number
  title: string
  overview: string | null
  poster_url: string | null
  trailer_key: string | null
  release_date: string | null
  genres: any | null
  last_validated_at: string
}

// Env vars
const supabaseUrl = Deno.env.get("SUPABASE_URL") || ""
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || ""
const tmdbApiKey = Deno.env.get("TMDB_API_KEY") || ""

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabase = createClient(supabaseUrl, supabaseServiceKey)
    const { id } = await req.json()

    if (!id || typeof id !== 'number') {
      return new Response(JSON.stringify({ error: "Invalid or missing movie ID" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    // 1. Check Cache
    const { data: cachedMovie, error: cacheError } = await supabase
      .from('movies_cache')
      .select('*')
      .eq('id', id)
      .single()

    const now = new Date()
    const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000

    if (cachedMovie && !cacheError) {
      const validatedAt = new Date(cachedMovie.last_validated_at)
      if (now.getTime() - validatedAt.getTime() < SEVEN_DAYS_MS) {
        console.log(`Cache HIT for movie ${id}`)
        return new Response(JSON.stringify(cachedMovie), {
          headers: { ...corsHeaders, "Content-Type": "application/json" }
        })
      }
    }

    console.log(`Cache MISS or EXPIRED for movie ${id}. Fetching from TMDB...`)

    // 2. Fetch from TMDB
    if (!tmdbApiKey) {
      throw new Error("TMDB_API_KEY is not configured")
    }

    const tmdbResponse = await fetch(`https://api.themoviedb.org/3/movie/${id}?api_key=${tmdbApiKey}&append_to_response=videos`)
    if (!tmdbResponse.ok) {
      return new Response(JSON.stringify({ error: `TMDB API error: ${tmdbResponse.statusText}` }), {
        status: tmdbResponse.status,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      })
    }

    const tmdbData = await tmdbResponse.json()

    // 3. Validate Poster
    let validPosterUrl = null
    if (tmdbData.poster_path) {
      const posterUrl = `https://image.tmdb.org/t/p/w500${tmdbData.poster_path}`
      try {
        const headRes = await fetch(posterUrl, { method: 'HEAD' })
        if (headRes.ok) {
          validPosterUrl = posterUrl
        }
      } catch (e) {
        console.error(`Failed to validate poster for ${id}:`, e)
      }
    }

    // 4. Validate Trailer
    let validTrailerKey = null
    if (tmdbData.videos && tmdbData.videos.results) {
      const trailers = tmdbData.videos.results.filter((v: any) => v.site === 'YouTube' && v.type === 'Trailer')
      if (trailers.length > 0) {
        // Just take the first YouTube trailer key, we assume YT links are mostly stable, 
        // but could add an oEmbed check if strictly necessary.
        validTrailerKey = trailers[0].key
      }
    }

    // 5. Construct Movie object
    const movieToCache = {
      id: tmdbData.id,
      title: tmdbData.title,
      overview: tmdbData.overview,
      poster_url: validPosterUrl,
      trailer_key: validTrailerKey,
      release_date: tmdbData.release_date || null,
      genres: tmdbData.genres || [],
      last_validated_at: now.toISOString()
    }

    // 6. Upsert to Cache
    const { error: upsertError } = await supabase
      .from('movies_cache')
      .upsert(movieToCache)

    if (upsertError) {
      console.error(`Failed to upsert cache for ${id}:`, upsertError)
      // Continue to return data even if cache fails
    }

    return new Response(JSON.stringify(movieToCache), {
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    })

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" }
    })
  }
})