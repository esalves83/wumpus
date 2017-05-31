package pcs.ia.wumpus.util;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class DuplicateMap <K,V> {
	
	private Map<K, ArrayList<V>> m = new HashMap<>();

    public void put(K k, V v) {
        if (m.containsKey(k)) {
            m.get(k).add(v);
        } else {
            ArrayList<V> arr = new ArrayList<>();
            arr.add(v);
            m.put(k, arr);
        }
    }

    public int size(){
    	return m.size();
    }
    
    public ArrayList<V> get(K k) {
        return m.get(k);
    }

    public V get(K k, int index) {
        return m.get(k).size()-1 < index ? null : m.get(k).get(index);
    }
}
